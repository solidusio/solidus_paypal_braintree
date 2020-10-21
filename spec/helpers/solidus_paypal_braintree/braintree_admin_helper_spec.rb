require 'spec_helper'

RSpec.describe SolidusPaypalBraintree::BraintreeAdminHelper do
  describe '#braintree_transaction_link' do
    subject { helper.braintree_transaction_link(payment) }

    let(:payment_method) { create_gateway }
    let(:payment) do
      instance_double(Spree::Payment, payment_method: payment_method, response_code: 'abcde')
    end
    let(:merchant_id) { payment_method.preferences[:merchant_id] }

    it 'generates a link to Braintree admin' do
      expect(subject).to eq "<a title=\"Show payment on Braintree\" target=\"_blank\" rel=\"noopener\" href=\"https://sandbox.braintreegateway.com/merchants/#{merchant_id}/transactions/abcde\">abcde</a>" # rubocop:disable Layout/LineLength
    end
  end
end
