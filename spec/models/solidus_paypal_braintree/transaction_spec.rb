require 'spec_helper'

describe SolidusPaypalBraintree::Transaction do
  describe "#valid?" do
    subject { transaction.valid? }

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
          name: "Bruce Wayne",
          address_line_1: "42 Spruce Lane",
          city: "Gotham",
          zip: "98201",
          state_code: "WA",
          country_code: "US"
        }
      }
    end
    let(:transaction) { described_class.new(valid_attributes) }

    before do
      create(:country, iso: "US")
    end

    it { is_expected.to be true }

    context 'without nonce' do
      let(:valid_attributes) { super().except(:nonce) }

      it { is_expected.to be false }
    end

    context 'without gateway' do
      let(:valid_attributes) { super().except(:payment_method) }

      it { is_expected.to be false }
    end

    context 'with bad gateway' do
      let(:valid_attributes) { super().merge(payment_method: Spree::PaymentMethod.new) }

      it { is_expected.to be false }
    end

    context 'without payment_type' do
      let(:valid_attributes) { super().except(:payment_type) }

      it { is_expected.to be false }
    end

    context 'without email' do
      let(:valid_attributes) { super().except(:email) }

      it { is_expected.to be false }
    end

    context "with valid address" do
      let(:valid_attributes) { super().merge(valid_address_attributes) }

      it { is_expected.to be true }
    end

    context "with invalid address" do
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
