require 'braintree'

module SolidusPaypalBraintree
  class Gateway < ::Spree::PaymentMethod
    TOKEN_GENERATION_DISABLED_MESSAGE = 'Token generation is disabled.' \
      ' To re-enable set the `token_generation_enabled` preference on the' \
      ' gateway to `true`.'.freeze

    PAYPAL_OPTIONS = {
      store_in_vault_on_success: true,
      submit_for_settlement: true
    }.freeze

    PAYPAL_AUTHORIZE_OPTIONS = {
      store_in_vault_on_success: true
    }.freeze

    ALLOWED_BRAINTREE_OPTIONS = [
      :device_data,
      :device_session_id,
      :merchant_account_id,
      :order_id
    ]

    VOIDABLE_STATUSES = [
      Braintree::Transaction::Status::SubmittedForSettlement,
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

    def method_type
      "paypal_braintree"
    end

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
        logger: Braintree::Configuration.logger.clone
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
      result = braintree.transaction.sale(
        amount: dollars(money_cents),
        options: PAYPAL_OPTIONS,
        **transaction_options(source, gateway_options)
      )

      Response.build(result)
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
      result = braintree.transaction.sale(
        amount: dollars(money_cents),
        options: PAYPAL_AUTHORIZE_OPTIONS,
        **transaction_options(source, gateway_options)
      )

      Response.build(result)
    end

    # Collect funds from an authorized payment.
    #
    # @api public
    # @param money_cents [Number, String]
    #   amount to capture (partial settlements are supported by the gateway)
    # @param response_code [String] the transaction id of the payment to capture
    # @return [Response]
    def capture(money_cents, response_code, _gateway_options)
      result = braintree.transaction.submit_for_settlement(
        response_code,
        dollars(money_cents)
      )
      Response.build(result)
    end

    # Used to refeund a customer for an already settled transaction.
    #
    # @api public
    # @param money_cents [Number, String] amount to refund
    # @param response_code [String] the transaction id of the payment to refund
    # @return [Response]
    def credit(money_cents, _source, response_code, _gateway_options)
      result = braintree.transaction.refund(
        response_code,
        dollars(money_cents)
      )
      Response.build(result)
    end

    # Used to cancel a transaction before it is settled.
    #
    # @api public
    # @param response_code [String] the transaction id of the payment to void
    # @return [Response]
    def void(response_code, _source, _gateway_options)
      result = braintree.transaction.void(response_code)
      Response.build(result)
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
      transaction = braintree.transaction.find(response_code)
      if VOIDABLE_STATUSES.include?(transaction.status)
        void(response_code, nil, {})
      else
        credit(cents(transaction.amount), nil, response_code, {})
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

    private

    def dollars(cents)
      Money.new(cents).dollars
    end

    def cents(dollars)
      dollars.to_money.cents
    end

    def transaction_options(source, options)
      params = options.select do |key, _|
        ALLOWED_BRAINTREE_OPTIONS.include?(key)
      end

      if source.token
        params[:payment_method_token] = source.token
      else
        params[:payment_method_nonce] = source.nonce
      end

      if source.customer.present?
        params[:customer_id] = source.customer.braintree_customer_id
      end

      params
    end

    def customer_profile_params(payment)
      params = {}

      if payment.source.try(:nonce)
        params[:payment_method_nonce] = payment.source.nonce
      end

      params
    end
  end
end
