require 'spec_helper'

describe SolidusPaypalBraintree::BraintreeAdapter do
  subject { described_class }

  describe '.all_transactions', vcr: {
    cassette_name: 'braintree_adapter/all_transactions',
    match_requests_on: [:method, :uri]
  } do
    let(:all_transactions) { subject.all_transactions }
    it 'returns a braintree resource collection' do
      expect(all_transactions).to be_a(Braintree::ResourceCollection)
    end
  end
end
