# frozen_string_literal: true

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

        test = true
        authorization = transaction.id
        fraud_review = nil
        avs_result = nil
        cvv_result = nil

        options = {
          test: test,
          authorization: authorization,
          fraud_review: fraud_review,
          avs_result: avs_result,
          cvv_result: cvv_result
        }

        new(true, transaction.status, {}, options)
      end

      def build_failure(result)
        new(false, error_message(result))
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
