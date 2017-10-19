# frozen_string_literal: true

require 'active_merchant/billing/response'
require_relative 'avs_result'

# Response object that all actions on the gateway should return
module SolidusPaypalBraintree
  class Response < ActiveMerchant::Billing::Response
    # def initialize(success, message, params = {}, options = {})

    class << self
      private :new

      # @param result [Braintree::SuccessfulResult, Braintree::ErrorResult]
      def build(result)
        result.success? ? build_success(result) : build_failure(result)
      end

      private

      def build_success(result)
        transaction = result.transaction
        new(true, transaction.status, {}, response_options(transaction))
      end

      def build_failure(result)
        transaction = result.transaction
        options = response_options(transaction).update(
          # For error responses we want to have the CVV code
          cvv_result: transaction.try!(:cvv_response_code)
        )
        new(false, error_message(result), result.params, options)
      end

      def response_options(transaction)
        # Some error responses do not have a transaction
        return {} if transaction.nil?
        {
          authorization: transaction.id,
          avs_result: AVSResult.build(transaction),
          # As we do not provide the CVV while submitting the transaction (for PCI compliance reasons),
          # we need to ignore the only response we get back (I = not provided).
          # Otherwise Solidus thinks this payment is risky.
          cvv_result: nil
        }
      end

      def error_message(result)
        if result.errors.any?
          result.errors.map { |e| "#{e.message} (#{e.code})" }.join(" ")
        else
          transaction_error_message(result.transaction)
        end
      end

      # Human readable error message for transaction responses
      def transaction_error_message(transaction)
        case transaction.status
        when 'gateway_rejected'
          I18n.t(transaction.gateway_rejection_reason,
            scope: 'solidus_paypal_braintree.gateway_rejection_reasons',
            default: "#{transaction.status.humanize} #{transaction.gateway_rejection_reason.humanize}")
        when 'processor_declined'
          I18n.t(transaction.processor_response_code,
            scope: 'solidus_paypal_braintree.processor_response_codes',
            default: "#{transaction.processor_response_text} (#{transaction.processor_response_code})")
        when 'settlement_declined'
          I18n.t(transaction.processor_settlement_response_code,
            scope: 'solidus_paypal_braintree.processor_settlement_response_codes',
            default: "#{transaction.processor_settlement_response_text} (#{transaction.processor_settlement_response_code})")
        else
          I18n.t(transaction.status,
            scope: 'solidus_paypal_braintree.transaction_statuses',
            default: transaction.status.humanize)
        end
      end
    end
  end
end
