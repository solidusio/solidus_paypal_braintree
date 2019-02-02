require 'braintree'

module SolidusPaypalBraintree
  class Gateway < ::Spree::PaymentMethod
    include RequestProtection

    # Error message from Braintree that gets returned by a non voidable transaction
    NON_VOIDABLE_STATUS_ERROR_REGEXP = /can only be voided if status is authorized/

    TOKEN_GENERATION_DISABLED_MESSAGE = 'Token generation is disabled.' \
      ' To re-enable set the `token_generation_enabled` preference on the' \
      ' gateway to `true`.'.freeze

    ALLOWED_BRAINTREE_OPTIONS = [
      :device_data,
      :device_session_id,
      :merchant_account_id,
      :order_id
    ]

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
    preference(:merchant_currency_map, :hash, default: {})
    preference(:paypal_payee_email_map, :hash, default: {})

    # Which checkout flow to use (vault/checkout)
    preference(:paypal_flow, :string, default: 'vault')

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
          **transaction_options(source, gateway_options, true)
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
      fail Spree::Core::GatewayError, result.message unless result.success?

      customer = result.customer

      source.create_customer!(braintree_customer_id: customer.id).tap do
        if customer.payment_methods.any?
          source.token = customer.payment_methods.last.token
        end

        source.save!
      end
    end

    # @return [String]
    #   The token that should be used along with the Braintree js-client sdk.
    #
    #   returns an error message if `preferred_token_generation_enabled` is
    #   set to false.
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
      return TOKEN_GENERATION_DISABLED_MESSAGE unless preferred_token_generation_enabled
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

    def convert_preference_value(value, type)
      if type == :hash && value.is_a?(String)
        value = to_hash(value)
      end
      super
    end

    def transaction_options(source, options, submit_for_settlement = false)
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
      if options[:currency]
        preferred_merchant_currency_map[options[:currency]]
      end
    end

    def paypal_payee_email_for(source, options)
      if source.paypal?
        preferred_paypal_payee_email_map[options[:currency]]
      end
    end

    def customer_profile_params(payment)
      params = {}

      if store_in_vault && payment.source.try(:nonce)
        params[:payment_method_nonce] = payment.source.nonce
      end

      params
    end
  end
end
