require 'spec_helper'

describe SolidusPaypalBraintree::Transaction do
  describe "#valid?" do
    let!(:country) { create :country, iso: "US" }
    let(:valid_attributes) do
      {
        nonce: 'abcde-fghjkl-lmnop',
        payment_method: SolidusPaypalBraintree::Gateway.new,
        payment_type: 'ApplePayCard',
        email: "test@example.com"
      }
    end
    let(:valid_address_attributes) do
      {
        address_attributes: {
          first_name: "Bruce",
          last_name: "Wayne",
          address_line_1: "42 Spruce Lane",
          city: "Gotham",
          zip: "98201",
          state_code: "WA",
          country_code: "US"
        }
      }
    end
    let(:transaction) { described_class.new(valid_attributes) }

    subject { transaction.valid? }

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
      let(:valid_attributes) { super().merge(payment_method: Spree::PaymentMethod.new) }
      it { is_expected.to be false }
    end

    context 'no payment_type' do
      let(:valid_attributes) { super().except(:payment_type) }
      it { is_expected.to be false }
    end

    context 'no email' do
      let(:valid_attributes) { super().except(:email) }
      it { is_expected.to be false }
    end

    context "valid address" do
      let(:valid_attributes) { super().merge(valid_address_attributes) }
      it { is_expected.to be true }
    end

    context "invalid address" do
      let(:valid_attributes) { super().merge(valid_address_attributes) }

      before { valid_address_attributes[:address_attributes][:zip] = nil }

      it { is_expected.to be false }

      it "sets useful error messages" do
        transaction.valid?
        expect(transaction.errors.full_messages).
          to eq ["Address zip can't be blank"]
      end
    end
  end
end
