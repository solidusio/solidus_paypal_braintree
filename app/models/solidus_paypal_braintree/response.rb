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
          [result.transaction.status,
           result.transaction.gateway_rejection_reason,
           result.transaction.processor_settlement_response_code,
           result.transaction.processor_settlement_response_text].compact.join(" ")
        end
      end
    end
  end
end
