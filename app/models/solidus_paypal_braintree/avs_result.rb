# frozen_string_literal: true

require 'active_merchant/billing/avs_result'

module SolidusPaypalBraintree
  class AVSResult < ActiveMerchant::Billing::AVSResult
    # Mapping took from ActiveMerchant::Billing::BraintreeBlueGateway
    AVS_MAPPING = {
      'M' => {
        'M' => 'M',
        'N' => 'A',
        'U' => 'B',
        'I' => 'B',
        'A' => 'B'
      },
      'N' => {
        'M' => 'Z',
        'N' => 'C',
        'U' => 'C',
        'I' => 'C',
        'A' => 'C'
      },
      'U' => {
        'M' => 'P',
        'N' => 'N',
        'U' => 'I',
        'I' => 'I',
        'A' => 'I'
      },
      'I' => {
        'M' => 'P',
        'N' => 'C',
        'U' => 'I',
        'I' => 'I',
        'A' => 'I'
      },
      'A' => {
        'M' => 'P',
        'N' => 'C',
        'U' => 'I',
        'I' => 'I',
        'A' => 'I'
      },
      nil => { nil => nil }
    }.freeze

    class << self
      private :new

      def build(transaction)
        new(
          code: avs_code_from(transaction),
          street_match: transaction.avs_street_address_response_code,
          postal_match: transaction.avs_postal_code_response_code
        )
      end

      private

      def avs_code_from(transaction)
        transaction.avs_error_response_code ||
          AVS_MAPPING[transaction.avs_street_address_response_code][transaction.avs_postal_code_response_code]
      end
    end
  end
end
