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

    # This is useful in feature tests to avoid rate limited requests from
    # Braintree
    preference(:client_sdk_enabled, :boolean, default: true)

    preference(:token_generation_enabled, :boolean, default: true)

    preference(:merchant_id, :string, default: nil)

    def payment_source_class
      Source
    end

    # @return [Response]
    def purchase(money, source, _gateway_options)
      result = ::Braintree::Transaction.sale(
        amount: money,
        payment_method_nonce: source.nonce,
        options: PAYPAL_OPTIONS
      )

      Response.build(result)
    end

    # @return [Response]
    def authorize(money, source, _gateway_options)
      result = ::Braintree::Transaction.sale(
        amount: money,
        payment_method_nonce: source.nonce,
        options: PAYPAL_AUTHORIZE_OPTIONS
      )

      Response.build(result)
    end

    # @return [Response]
    def capture(_money, _source, _gateway_options)
      raise NotImplementedError
    end

    # @return [Response]
    def credit(_money, _source, _response_code, _gateway_options)
      raise NotImplementedError
    end

    # Used to cancel a transaction before it is settled.
    #
    # @api public
    # @param response_code [String] the transaction id of the payment to void
    # @return [Response]
    def void(response_code, _source, _gateway_options)
      result = Braintree::Transaction.void(response_code)
      Response.build(result)
    end

    def create_profile(_payment)
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
      ::Braintree::ClientToken.generate
    end

    def payment_profiles_supported?
      true
    end
  end
end
