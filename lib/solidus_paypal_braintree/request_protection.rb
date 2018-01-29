require 'active_merchant/network_connection_retries'

module SolidusPaypalBraintree
  module RequestProtection
    include ActiveMerchant::NetworkConnectionRetries

    def protected_request
      raise ArgumentError unless block_given?
      options = {
        connection_exceptions: {
          Braintree::BraintreeError => 'Error while connecting to Braintree gateway'
        },
        logger: Rails.logger
      }
      retry_exceptions(options) { yield }
    end
  end
end
