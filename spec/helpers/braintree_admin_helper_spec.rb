require 'spec_helper'

RSpec.describe BraintreeAdminHelper do
  describe '#braintree_transaction_link' do
    let(:payment_method) { create_gateway }
    let(:payment) do
      double(Spree::Payment, payment_method: payment_method, response_code: 'abcde')
    end

    subject { helper.braintree_transaction_link(payment) }

    it 'should generate a link to Braintree admin' do
      expect(subject).to eq "<a title=\"Show payment on Braintree\" target=\"_blank\" href=\"https://sandbox.braintreegateway.com/merchants/7rdg92j7bm7fk5h3/transactions/abcde\">abcde</a>"
    end
  end
end
