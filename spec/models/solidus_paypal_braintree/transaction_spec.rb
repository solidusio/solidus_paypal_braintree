require 'spec_helper'

describe SolidusPaypalBraintree::Transaction do
  describe "#valid?" do
    let(:valid_attributes) do
      {
        nonce: 'abcde-fghjkl-lmnop',
        payment_method: SolidusPaypalBraintree::Gateway.new,
        payment_type: 'ApplePayCard',
        phone: "555-1234",
        email: "test@example.com"
      }
    end

    subject { described_class.new(valid_attributes).valid? }

    it { is_expected.to be true }

    context 'no nonce' do
      let(:valid_attributes) { super().except(:nonce) }
      it { is_expected.to be false }
    end

    context 'no gateway' do
      let(:valid_attributes) { super().except(:payment_method) }
      it { is_expected.to be false }
    end

    context 'bad gateway' do
      let(:valid_attributes) { super().merge(payment_method: Spree::Gateway.new) }
      it { is_expected.to be false }
    end

    context 'no payment_type' do
      let(:valid_attributes) { super().except(:payment_type) }
      it { is_expected.to be false }
    end

    context 'no phone' do
      let(:valid_attributes) { super().except(:phone) }
      it { is_expected.to be false }
    end

    context 'no email' do
      let(:valid_attributes) { super().except(:email) }
      it { is_expected.to be false }
    end
  end
end
