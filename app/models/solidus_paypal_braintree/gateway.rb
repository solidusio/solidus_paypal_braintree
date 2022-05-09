# frozen_string_literal: true

require 'braintree'

module SolidusPaypalBraintree
  class Gateway < ::Spree::PaymentMethod
    include RequestProtection

    class TokenGenerationDisabledError < StandardError; end

    # Error message from Braintree that gets returned by a non voidable transaction
    NON_VOIDABLE_STATUS_ERROR_REGEXP = /can only be voided if status is authorized/.freeze

    TOKEN_GENERATION_DISABLED_MESSAGE = 'Token generation is disabled.' \
                                        ' To re-enable set the `token_generation_enabled` preference on the' \
                                        ' gateway to `true`.'

    ALLOWED_BRAINTREE_OPTIONS = [
      :device_data,
      :device_session_id,
      :merchant_account_id,
      :order_id
    ].freeze

    VOIDABLE_STATUSES = [
      Braintree::Transaction::Status::SubmittedForSettlement,
      Braintree::Transaction::Status::SettlementPending,
      Braintree::Transaction::Status::Authorized
    ].freeze

    # This is useful in feature tests to avoid rate limited requests from
    # Braintree
    preference(:client_sdk_enabled, :boolean, default: true)

    preference(:token_generation_enabled, :boolean, default: true)

    # Preferences for configuration of Braintree credentials
    preference(:environment, :string, default: 'sandbox')
    preference(:merchant_id, :string, default: nil)
    preference(:public_key,  :string, default: nil)
    preference(:private_key, :string, default: nil)
    preference(:http_open_timeout, :integer, default: 60)
    preference(:http_read_timeout, :integer, default: 60)
    preference(:merchant_currency_map, :hash, default: {})
    preference(:paypal_payee_email_map, :hash, default: {})

    # Which checkout flow to use (vault/checkout)
    preference(:paypal_flow, :string, default: 'vault')

    # A hash that gets passed to the `style` key when initializing the credit card fields.
    # See https://developers.braintreepayments.com/guides/hosted-fields/styling/javascript/v3
    preference(:credit_card_fields_style, :hash, default: {})

    # A hash that gets its keys passed to the associated braintree field placeholder tag.
    # Example: { number: "Enter card number", cvv: "Enter CVV", expirationDate: "mm/yy" }
    preference(:placeholder_text, :hash, default: {})

    # Wether to use the JS device data collector
    preference(:use_data_collector, :boolean, default: true)

    # Useful for testing purposes, as PayPal will show funding sources based on the buyer's country;
    # usually retrieved by their  ip geolocation. I.e. Venmo will show for US buyers, but not European.
    preference(:force_buyer_country, :string)

    preference(:enable_venmo_funding, :boolean, default: false)

    # When on mobile, paying with Venmo, the user may be returned to the same store tab
    # depending on if their browser supports it, otherwise a new tab will be created
    # However, returning to a new tab may break the payment checkout flow for some stores, for example,
    # if they are single-page applications (SPA). Set this to false if this is the case
    preference(:venmo_new_tab_support, :boolean, default: true)

    def partial_name
      "paypal_braintree"
    end
    alias_method :method_type, :partial_name

    def payment_source_class
      Source
    end

    def braintree
      @braintree ||= Braintree::Gateway.new(gateway_options)
    end

    def gateway_options
      {
        environment: preferred_environment.to_sym,
        merchant_id: preferred_merchant_id,
        public_key: preferred_public_key,
        private_key: preferred_private_key,
        http_open_timeout: preferred_http_open_timeout,
        http_read_timeout: preferred_http_read_timeout,
        logger: logger
      }
    end

    # Create a payment and submit it for settlement all at once.
    #
    # @api public
    # @param money_cents [Number, String] amount to authorize
    # @param source [Source] payment source
    # @params gateway_options [Hash]
    #   extra options to send along. e.g.: device data for fraud prevention
    # @return [Response]
    def purchase(money_cents, source, gateway_options)
      protected_request do
        result = braintree.transaction.sale(
          amount: dollars(money_cents),
          **transaction_options(source, gateway_options, submit_for_settlement: true)
        )

        Response.build(result)
      end
    end

    # Authorize a payment to be captured later.
    #
    # @api public
    # @param money_cents [Number, String] amount to authorize
    # @param source [Source] payment source
    # @params gateway_options [Hash]
    #   extra options to send along. e.g.: device data for fraud prevention
    # @return [Response]
    def authorize(money_cents, source, gateway_options)
      protected_request do
        result = braintree.transaction.sale(
          amount: dollars(money_cents),
          **transaction_options(source, gateway_options)
        )

        Response.build(result)
      end
    end

    # Collect funds from an authorized payment.
    #
    # @api public
    # @param money_cents [Number, String]
    #   amount to capture (partial settlements are supported by the gateway)
    # @param response_code [String] the transaction id of the payment to capture
    # @return [Response]
    def capture(money_cents, response_code, _gateway_options)
      protected_request do
        result = braintree.transaction.submit_for_settlement(
          response_code,
          dollars(money_cents)
        )
        Response.build(result)
      end
    end

    # Used to refeund a customer for an already settled transaction.
    #
    # @api public
    # @param money_cents [Number, String] amount to refund
    # @param response_code [String] the transaction id of the payment to refund
    # @return [Response]
    def credit(money_cents, _source, response_code, _gateway_options)
      protected_request do
        result = braintree.transaction.refund(
          response_code,
          dollars(money_cents)
        )
        Response.build(result)
      end
    end

    # Used to cancel a transaction before it is settled.
    #
    # @api public
    # @param response_code [String] the transaction id of the payment to void
    # @return [Response]
    def void(response_code, _source, _gateway_options)
      protected_request do
        result = braintree.transaction.void(response_code)
        Response.build(result)
      end
    end

    # Will either refund or void the payment depending on its state.
    #
    # If the transaction has not yet been settled, we can void the transaction.
    # Otherwise, we need to issue a refund.
    #
    # @api public
    # @param response_code [String] the transaction id of the payment to void
    # @return [Response]
    def cancel(response_code)
      transaction = protected_request do
        braintree.transaction.find(response_code)
      end
      if VOIDABLE_STATUSES.include?(transaction.status)
        void(response_code, nil, {})
      else
        credit(cents(transaction.amount), nil, response_code, {})
      end
    end

    # Will void the payment depending on its state or return false
    #
    # Used by Solidus >= 2.4 instead of +cancel+
    #
    # If the transaction has not yet been settled, we can void the transaction.
    # Otherwise, we return false so Solidus creates a refund instead.
    #
    # @api public
    # @param payment [Spree::Payment] the payment to void
    # @return [Response|FalseClass]
    def try_void(payment)
      transaction = braintree.transaction.find(payment.response_code)
      if transaction.status.in? SolidusPaypalBraintree::Gateway::VOIDABLE_STATUSES
        # Sometimes Braintree returns a voidable status although it is not voidable anymore.
        # When we try to void that transaction we receive an error and need to return false
        # so Solidus can create a refund instead.
        begin
          void(payment.response_code, nil, {})
        rescue ActiveMerchant::ConnectionError => e
          e.message.match(NON_VOIDABLE_STATUS_ERROR_REGEXP) ? false : raise(e)
        end
      else
        false
      end
    end

    # Creates a new customer profile in Braintree
    #
    # @api public
    # @param payment [Spree::Payment]
    # @return [SolidusPaypalBraintree::Customer]
    def create_profile(payment)
      source = payment.source

      return if source.token.present? || source.customer.present? || source.nonce.nil?

      result = braintree.customer.create(customer_profile_params(payment))
      fail ::Spree::Core::GatewayError, result.message unless result.success?

      customer = result.customer

      source.create_customer!(braintree_customer_id: customer.id).tap do
        if customer.payment_methods.any?
          source.token = customer.payment_methods.last.token
        end

        source.save!
      end
    end

    # @raise [TokenGenerationDisabledError]
    #   If `preferred_token_generation_enabled` is false
    #
    # @return [String]
    #   The token that should be used along with the Braintree js-client sdk.
    #
    # @example
    #   <script>
    #     var token = #{Spree::Braintree::Gateway.first!.generate_token}
    #
    #     braintree.client.create(
    #       {
    #         authorization: token
    #       },
    #       function(clientError, clientInstance) {
    #         ...
    #       }
    #     );
    #   </script>
    def generate_token
      unless preferred_token_generation_enabled
        raise TokenGenerationDisabledError, TOKEN_GENERATION_DISABLED_MESSAGE
      end

      braintree.client_token.generate
    end

    def payment_profiles_supported?
      true
    end

    def sources_by_order(order)
      source_ids = order.payments.where(payment_method_id: id).pluck(:source_id).uniq
      payment_source_class.where(id: source_ids).with_payment_profile
    end

    def reusable_sources(order)
      if order.completed?
        sources_by_order(order)
      elsif order.user_id
        payment_source_class.where(
          payment_method_id: id,
          user_id: order.user_id
        ).with_payment_profile
      else
        []
      end
    end

    private

    # Whether to store this payment method in the PayPal Vault. This only works when the checkout
    # flow is "vault", so make sure to call +super+ if you override it.
    def store_in_vault
      preferred_paypal_flow == 'vault'
    end

    def logger
      Braintree::Configuration.logger.clone.tap do |logger|
        logger.level = Rails.logger.level
      end
    end

    def dollars(cents)
      Money.new(cents).dollars
    end

    def cents(dollars)
      dollars.to_money.cents
    end

    def to_hash(preference_string)
      JSON.parse(preference_string.gsub("=>", ":"))
    end

    def convert_preference_value(value, type, preference_encryptor = nil)
      if type == :hash && value.is_a?(String)
        value = to_hash(value)
      end
      if method(__method__).super_method.arity == 3
        super
      else
        super(value, type)
      end
    end

    def transaction_options(source, options, submit_for_settlement: false)
      params = options.select do |key, _|
        ALLOWED_BRAINTREE_OPTIONS.include?(key)
      end

      params[:channel] = "Solidus"
      params[:options] = { store_in_vault_on_success: store_in_vault }

      if submit_for_settlement
        params[:options][:submit_for_settlement] = true
      end

      if paypal_email = paypal_payee_email_for(source, options)
        params[:options][:paypal] = { payee_email: paypal_email }
      end

      if source.venmo? && venmo_business_profile_id
        params[:options][:venmo] = { profile_id: venmo_business_profile_id }
      end

      if merchant_account_id = merchant_account_for(source, options)
        params[:merchant_account_id] = merchant_account_id
      end

      if source.token
        params[:payment_method_token] = source.token
      else
        params[:payment_method_nonce] = source.nonce
      end

      if source.paypal?
        params[:shipping] = braintree_shipping_address(options)
      end

      if source.credit_card?
        params[:billing] = braintree_billing_address(options)
      end

      if source.customer.present?
        params[:customer_id] = source.customer.braintree_customer_id
      end

      params
    end

    def braintree_shipping_address(options)
      braintree_address_attributes(options[:shipping_address])
    end

    def braintree_billing_address(options)
      braintree_address_attributes(options[:billing_address])
    end

    def braintree_address_attributes(address)
      first, last = address[:name].split(" ", 2)
      {
        first_name: first,
        last_name: last,
        street_address: [address[:address1], address[:address2]].compact.join(" "),
        locality: address[:city],
        postal_code: address[:zip],
        region: address[:state],
        country_code_alpha2: address[:country]
      }
    end

    def merchant_account_for(_source, options)
      return unless options[:currency]

      preferred_merchant_currency_map[options[:currency]]
    end

    def paypal_payee_email_for(source, options)
      return unless source.paypal?

      preferred_paypal_payee_email_map[options[:currency]]
    end

    def customer_profile_params(payment)
      params = {}

      params[:email] = payment&.order&.email

      if store_in_vault && payment.source.try(:nonce)
        params[:payment_method_nonce] = payment.source.nonce
      end

      params
    end

    # override with the Venmo business profile that you want to use for transactions,
    # or leave it to be nil if want Braintree to use your default account
    def venmo_business_profile_id
      nil
    end
  end
end
