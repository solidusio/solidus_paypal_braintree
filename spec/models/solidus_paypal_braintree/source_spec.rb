require 'spec_helper'

RSpec.describe SolidusPaypalBraintree::Source, type: :model do
  describe '#payment_method' do
    it 'uses spree_payment_method' do
      expect(described_class.new.build_payment_method).to be_a Spree::PaymentMethod
    end
  end
end
