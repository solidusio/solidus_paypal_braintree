require 'spec_helper'

RSpec.describe SolidusPaypalBraintree::Source, type: :model do
  describe '#payment_method' do
    it 'uses spree_payment_method' do
      expect(described_class.new.build_payment_method).to be_a Spree::PaymentMethod
    end
  end

  describe '#imported' do
    it 'is always false' do
      expect(described_class.new.imported).to_not be
    end
  end

  describe "#actions" do
    it "supports capture, void, and credit" do
      expect(described_class.new.actions).to eq %w[capture void credit]
    end
  end

  describe "#can_capture?" do
    subject { described_class.new.can_capture?(payment) }

    context "when the payment state is pending" do
      let(:payment) { build_stubbed(:payment, state: "pending") }

      it { is_expected.to be }
    end

    context "when the payment state is checkout" do
      let(:payment) { build_stubbed(:payment, state: "checkout") }

      it { is_expected.to be }
    end

    context "when the payment is completed" do
      let(:payment) { build_stubbed(:payment, state: "completed") }

      it { is_expected.to_not be }
    end
  end

  describe "#can_void?" do
    subject { described_class.new.can_void?(payment) }

    context "when the payment failed" do
      let(:payment) { build_stubbed(:payment, state: "failed") }

      it { is_expected.not_to be }
    end

    context "when the payment is already voided" do
      let(:payment) { build_stubbed(:payment, state: "void") }

      it { is_expected.not_to be }
    end

    context "when the payment is completed" do
      let(:payment) { build_stubbed(:payment, state: "completed") }

      it { is_expected.to be }
    end
  end

  describe "#can_credit?" do
    subject { described_class.new.can_credit?(payment) }

    context "when the payment is completed" do
      context "and the credit allowed is 100" do
        let(:payment) { build_stubbed(:payment, state: "completed", amount: 100) }

        it { is_expected.to be }
      end

      context "and the credit allowed is 0" do
        let(:payment) { build_stubbed(:payment, state: "completed", amount: 0) }

        it { is_expected.not_to be }
      end
    end

    context "when the payment has not been completed" do
      let(:payment) { build_stubbed(:payment, state: "checkout") }

      it { is_expected.not_to be }
    end
  end

  describe "#friendly_payment_type" do
    subject { described_class.new(payment_type: type).friendly_payment_type }

    context "when then payment type is PayPal" do
      let(:type) { "PayPalAccount" }

      it "returns the translated payment type" do
        expect(subject).to eq "PayPal"
      end
    end

    context "when the payment type is Apple Pay" do
      let(:type) { "ApplePayCard" }

      it "returns the translated payment type" do
        expect(subject).to eq "Apple Pay"
      end
    end
  end

  describe "#apple_pay?" do
    subject { described_class.new(payment_type: type).apple_pay? }

    context "when the payment type is Apple Pay" do
      let(:type) { "ApplePayCard" }

      it { is_expected.to be true }
    end

    context "when the payment type is not PayPal" do
      let(:type) { "DogeCoin" }

      it { is_expected.to be false }
    end
  end

  describe "#paypal?" do
    subject { described_class.new(payment_type: type).paypal? }

    context "when the payment type is PayPal" do
      let(:type) { "PayPalAccount" }

      it { is_expected.to be true }
    end

    context "when the payment type is not PayPal" do
      let(:type) { "MonopolyMoney" }

      it { is_expected.to be false }
    end
  end
end
