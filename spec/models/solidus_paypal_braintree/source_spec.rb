require 'spec_helper'

RSpec.describe SolidusPaypalBraintree::Source, type: :model do
  it 'is invalid without a payment_type set' do
    expect(described_class.new).to be_invalid
  end

  it 'is invalid with payment_type set to unknown type' do
    expect(described_class.new(payment_type: 'AndroidPay')).to be_invalid
  end

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
      let(:payment) { build(:payment, state: "pending") }

      it { is_expected.to be }
    end

    context "when the payment state is checkout" do
      let(:payment) { build(:payment, state: "checkout") }

      it { is_expected.to be }
    end

    context "when the payment is completed" do
      let(:payment) { build(:payment, state: "completed") }

      it { is_expected.to_not be }
    end
  end

  describe '#can_void?' do
    let(:payment_source) { described_class.new }
    let(:payment) { build(:payment) }

    let(:transaction_response) do
      double(status: Braintree::Transaction::Status::SubmittedForSettlement)
    end

    let(:transaction_request) do
      double(find: transaction_response)
    end

    subject { payment_source.can_void?(payment) }

    before do
      allow(payment_source).to receive(:braintree_client) do
        double(transaction: transaction_request)
      end
    end

    context 'when transaction id is not present' do
      let(:payment) { build(:payment, response_code: nil) }

      it { is_expected.to be(false) }
    end

    context 'when transaction has voidable status' do
      it { is_expected.to be(true) }
    end

    context 'when transaction has non voidable status' do
      let(:transaction_response) do
        double(status: Braintree::Transaction::Status::Settled)
      end

      it { is_expected.to be(false) }
    end

    context 'when transaction is not found at Braintreee' do
      before do
        allow(transaction_request).to \
          receive(:find).and_raise(Braintree::NotFoundError)
      end

      it { is_expected.to be(false) }
    end
  end

  describe "#can_credit?" do
    subject { described_class.new.can_credit?(payment) }

    context "when the payment is completed" do
      context "and the credit allowed is 100" do
        let(:payment) { build(:payment, state: "completed", amount: 100) }

        it { is_expected.to be }
      end

      context "and the credit allowed is 0" do
        let(:payment) { build(:payment, state: "completed", amount: 0) }

        it { is_expected.not_to be }
      end
    end

    context "when the payment has not been completed" do
      let(:payment) { build(:payment, state: "checkout") }

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

    context "when the payment type is Credit Card" do
      let(:type) { "CreditCard" }

      it "returns the translated payment type" do
        expect(subject).to eq "Credit Card"
      end
    end
  end

  describe "#apple_pay?" do
    subject { described_class.new(payment_type: type).apple_pay? }

    context "when the payment type is Apple Pay" do
      let(:type) { "ApplePayCard" }

      it { is_expected.to be true }
    end

    context "when the payment type is not Apple Pay" do
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

  describe "#credit_card?" do
    subject { described_class.new(payment_type: type).credit_card? }

    context "when the payment type is CreditCard" do
      let(:type) { "CreditCard" }

      it { is_expected.to be true }
    end

    context "when the payment type is not CreditCard" do
      let(:type) { "MonopolyMoney" }

      it { is_expected.to be false }
    end
  end

  shared_context 'unknown source token' do
    let(:braintree_payment_method) { double }

    before do
      allow(braintree_payment_method).to receive(:find) do
        raise Braintree::NotFoundError
      end
      allow(payment_source).to receive(:braintree_client) do
        double(payment_method: braintree_payment_method)
      end
    end
  end

  shared_context 'nil source token' do
    let(:braintree_payment_method) { double }

    before do
      allow(braintree_payment_method).to receive(:find) do
        raise ArgumentError
      end
      allow(payment_source).to receive(:braintree_client) do
        double(payment_method: braintree_payment_method)
      end
    end
  end

  describe "#last_4" do
    let(:method) { new_gateway.tap(&:save!) }
    let(:payment_source) { described_class.create!(payment_type: "CreditCard", payment_method: method) }
    let(:braintree_client) { method.braintree }

    subject { payment_source.last_4 }

    context 'when token is known at braintree', vcr: { cassette_name: "source/last4" } do
      before do
        customer = braintree_client.customer.create
        expect(customer.customer.id).to be

        method = braintree_client.payment_method.create({
          payment_method_nonce: "fake-valid-country-of-issuance-usa-nonce", customer_id: customer.customer.id
        })
        expect(method.payment_method.token).to be

        payment_source.update_attributes!(token: method.payment_method.token)
      end

      it "delegates to the braintree payment method" do
        method = braintree_client.payment_method.find(payment_source.token)
        expect(subject).to eql(method.last_4)
      end
    end

    context 'when the source token is not known at Braintree' do
      include_context 'unknown source token'

      it { is_expected.to be(nil) }
    end

    context 'when the source token is nil' do
      include_context 'nil source token'

      it { is_expected.to be(nil) }
    end
  end

  describe "#display_number" do
    let(:type) { nil }
    let(:payment_source) { described_class.new(payment_type: type) }
    subject { payment_source.display_number }

    context "when last_digits is a number" do
      before do
        allow(payment_source).to receive(:last_digits).and_return('1234')
      end

      it { is_expected.to eq 'XXXX-XXXX-XXXX-1234' }
    end

    context "when last_digits is nil" do
      before do
        allow(payment_source).to receive(:last_digits).and_return(nil)
      end

      it { is_expected.to eq 'XXXX-XXXX-XXXX-XXXX' }
    end

    context "when is a PayPal source" do
      let(:type) { "PayPalAccount" }

      before do
        allow(payment_source).to receive(:email).and_return('user@example.com')
      end

      it { is_expected.to eq 'user@example.com' }
    end
  end

  describe "#card_type" do
    let(:method) { new_gateway.tap(&:save!) }
    let(:payment_source) { described_class.create!(payment_type: "CreditCard", payment_method: method) }
    let(:braintree_client) { method.braintree }

    subject { payment_source.card_type }

    context "when the token is known at braintree", vcr: { cassette_name: "source/card_type" } do
      before do
        customer = braintree_client.customer.create
        expect(customer.customer.id).to be

        method = braintree_client.payment_method.create({
          payment_method_nonce: "fake-valid-country-of-issuance-usa-nonce", customer_id: customer.customer.id
        })
        expect(method.payment_method.token).to be

        payment_source.update_attributes!(token: method.payment_method.token)
      end

      it "delegates to the braintree payment method" do
        method = braintree_client.payment_method.find(payment_source.token)
        expect(subject).to eql(method.card_type)
      end
    end

    context 'when the source token is not known at Braintree' do
      include_context 'unknown source token'

      it { is_expected.to be_nil }
    end

    context 'when the source token is nil' do
      include_context 'nil source token'

      it { is_expected.to be_nil }
    end
  end

  describe '#reusable?' do
    let(:payment_source) { described_class.new(token: token, nonce: nonce) }
    let(:nonce) { 'nonce67890' }
    subject { payment_source.reusable? }

    context 'when source token is present' do
      let(:token) { 'token12345' }
      it { is_expected.to be_truthy }
    end

    context 'when source token is nil' do
      let(:token) { nil }
      it { is_expected.to be_falsy }
    end
  end
end
