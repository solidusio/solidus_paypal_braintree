require 'spec_helper'

RSpec.describe BraintreeAdminHelper do
  describe '#braintree_transaction_link' do
    let(:payment_method) { create_gateway }
    let(:payment) do
      double(Spree::Payment, payment_method: payment_method, response_code: 'abcde')
    end
    let(:merchant_id) { payment_method.preferences[:merchant_id] }

    subject { helper.braintree_transaction_link(payment) }

    it 'should generate a link to Braintree admin' do
      expect(subject).to eq "<a title=\"Show payment on Braintree\" target=\"_blank\" href=\"https://sandbox.braintreegateway.com/merchants/#{merchant_id}/transactions/abcde\">abcde</a>"
    end
  end
end
