# frozen_string_literal: true

require 'active_merchant/network_connection_retries'

module SolidusBraintree
  module RequestProtection
    include ActiveMerchant::NetworkConnectionRetries

    def protected_request(&block)
      raise ArgumentError unless block_given?

      options = {
        connection_exceptions: {
          Braintree::BraintreeError => 'Error while connecting to Braintree gateway'
        },
        logger: Rails.logger
      }
      retry_exceptions(options, &block)
    end
  end
end
