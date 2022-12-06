require 'spec_helper'

RSpec.describe SolidusBraintree::Source, type: :model do
  include_context 'when order is ready for payment'

  it 'is invalid without a payment_type set' do
    expect(described_class.new).to be_invalid
  end

  it 'is invalid with payment_type set to unknown type' do
    expect(described_class.new(payment_type: 'AndroidPay')).to be_invalid
  end

  describe 'attributes' do
    context 'with paypal_funding_source' do
      subject { build(:solidus_paypal_braintree_source, :paypal) }

      it 'can be nil' do
        subject.paypal_funding_source = nil

        expect(subject).to be_valid
      end

      it 'makes empty strings nil' do
        subject.paypal_funding_source = ''

        result = subject.save

        expect(result).to be(true)
        expect(subject.paypal_funding_source).to be_nil
      end

      it 'gets correctly mapped as an enum' do
        subject.paypal_funding_source = 'applepay'

        result = subject.save

        expect(result).to be(true)
        expect(subject.paypal_funding_source).to eq('applepay')
        expect(subject.applepay_funding?).to be(true)
      end

      it "doesn't become nil when the payment_type is a PAYPAL" do
        subject.payment_type = described_class::PAYPAL
        subject.paypal_funding_source = 'venmo'

        result = subject.save

        expect(result).to be(true)
        expect(subject.venmo_funding?).to be(true)
      end

      it 'becomes nil when the payment_type is a CREDIT CARD' do
        subject.payment_type = described_class::CREDIT_CARD
        subject.paypal_funding_source = 'venmo'

        result = subject.save

        expect(result).to be(true)
        expect(subject.paypal_funding_source).to be_nil
      end

      it 'becomes nil when the payment_type is APPLE PAY' do
        subject.payment_type = described_class::APPLE_PAY
        subject.paypal_funding_source = 'venmo'

        result = subject.save

        expect(result).to be(true)
        expect(subject.paypal_funding_source).to be_nil
      end
    end
  end

  describe '#payment_method' do
    it 'uses spree_payment_method' do
      expect(described_class.new.build_payment_method).to be_a Spree::PaymentMethod
    end
  end

  describe '#imported' do
    it 'is always false' do
      expect(described_class.new.imported).not_to be_truthy
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

      it { is_expected.to be_truthy }
    end

    context "when the payment state is checkout" do
      let(:payment) { build(:payment, state: "checkout") }

      it { is_expected.to be_truthy }
    end

    context "when the payment is completed" do
      let(:payment) { build(:payment, state: "completed") }

      it { is_expected.not_to be_truthy }
    end
  end

  describe '#can_void?' do
    subject { payment_source.can_void?(payment) }

    let(:payment_source) { described_class.new }
    let(:payment) { build(:payment) }

    let(:transaction_response) do
      double(:response, status: Braintree::Transaction::Status::SubmittedForSettlement)
    end

    let(:transaction_request) do
      double(:request, find: transaction_response)
    end

    before do
      allow(payment_source).to receive(:braintree_client) do
        double(:transaction, transaction: transaction_request)
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
        double(:response, status: Braintree::Transaction::Status::Settled)
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
      context "when the credit allowed is 100" do
        let(:payment) { build(:payment, state: "completed", amount: 100) }

        it { is_expected.to be_truthy }
      end

      context "when the credit allowed is 0" do
        let(:payment) { build(:payment, state: "completed", amount: 0) }

        it { is_expected.not_to be_truthy }
      end
    end

    context "when the payment has not been completed" do
      let(:payment) { build(:payment, state: "checkout") }

      it { is_expected.not_to be_truthy }
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

  describe "#venmo?" do
    subject { described_class.new(payment_type: type).venmo? }

    context "when the payment type is VenmoAccount" do
      let(:type) { "VenmoAccount" }

      it { is_expected.to be true }
    end

    context "when the payment type is not VenmoAccount" do
      let(:type) { "Swish" }

      it { is_expected.to be false }
    end
  end

  shared_context 'with unknown source token' do
    let(:braintree_payment_method) { double }

    before do
      allow(braintree_payment_method).to receive(:find) do
        raise Braintree::NotFoundError
      end
      allow(payment_source).to receive(:braintree_client) do
        instance_double(payment_method: braintree_payment_method)
      end
    end
  end

  shared_context 'with nil source token' do
    let(:braintree_payment_method) { double }

    before do
      allow(braintree_payment_method).to receive(:find) do
        raise ArgumentError
      end
      allow(payment_source).to receive(:braintree_client) do
        instance_double(payment_method: braintree_payment_method)
      end
    end
  end

  describe "#last_4" do
    subject { payment_source.last_4 }

    let(:method) { new_gateway.tap(&:save!) }
    let(:payment_source) { described_class.create!(payment_type: "CreditCard", payment_method: method) }
    let(:braintree_client) { method.braintree }

    context 'when token is known at braintree', vcr: {
      cassette_name: "source/last4",
      match_requests_on: [:braintree_uri]
    } do
      before do
        customer = braintree_client.customer.create

        method = braintree_client.payment_method.create({
          payment_method_nonce: "fake-valid-country-of-issuance-usa-nonce",
          customer_id: customer.customer.id
        })

        payment_source.update!(token: method.payment_method.token)
      end

      it "delegates to the braintree payment method" do
        method = braintree_client.payment_method.find(payment_source.token)
        expect(subject).to eql(method.last_4)
      end
    end

    context 'when the source token is not known at Braintree' do
      include_context 'with unknown source token'

      it { is_expected.to be_nil }
    end

    context 'when the source token is nil' do
      include_context 'with nil source token'

      it { is_expected.to be_nil }
    end
  end

  describe "#display_number" do
    subject { payment_source.display_number }

    let(:type) { nil }
    let(:payment_source) { described_class.new(payment_type: type) }

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

    context "when is a Venmo source" do
      let(:type) { "VenmoAccount" }

      before do
        allow(payment_source).to receive(:username).and_return('venmojoe')
      end

      it { is_expected.to eq('venmojoe') }
    end
  end

  describe "#card_type" do
    subject { payment_source.card_type }

    let(:method) { new_gateway.tap(&:save!) }
    let(:payment_source) { described_class.create!(payment_type: "CreditCard", payment_method: method) }
    let(:braintree_client) { method.braintree }

    context "when the token is known at braintree", vcr: {
      cassette_name: "source/card_type",
      match_requests_on: [:braintree_uri]
    } do
      before do
        customer = braintree_client.customer.create

        method = braintree_client.payment_method.create({
          payment_method_nonce: "fake-valid-country-of-issuance-usa-nonce", customer_id: customer.customer.id
        })

        payment_source.update!(token: method.payment_method.token)
      end

      it "delegates to the braintree payment method" do
        method = braintree_client.payment_method.find(payment_source.token)
        expect(subject).to eql(method.card_type)
      end
    end

    context 'when the source token is not known at Braintree' do
      include_context 'with unknown source token'

      it { is_expected.to be_nil }
    end

    context 'when the source token is nil' do
      include_context 'with nil source token'

      it { is_expected.to be_nil }
    end
  end

  describe '#display_paypal_funding_source' do
    let(:payment_source) { described_class.new }

    context 'when the EN locale exists' do
      it 'translates the funding source' do
        payment_source.paypal_funding_source = 'card'

        result = payment_source.display_paypal_funding_source

        expect(result).to eq('Credit or debit card')
      end
    end

    context "when the locale doesn't exist" do
      it 'returns the paypal_funding_source as the default' do
        allow(payment_source).to receive(:paypal_funding_source).and_return('non-existent')

        result = payment_source.display_paypal_funding_source

        expect(result).to eq('non-existent')
      end
    end
  end

  describe "#bin" do
    subject { payment_source.bin }

    let(:method) { new_gateway.tap(&:save!) }
    let(:payment_source) { described_class.create!(payment_type: "CreditCard", payment_method: method) }
    let(:braintree_client) { method.braintree }

    context "when the token is known at braintree", vcr: {
      cassette_name: "source/bin",
      match_requests_on: [:braintree_uri]
    } do
      before do
        customer = braintree_client.customer.create

        method = braintree_client.payment_method.create({
          payment_method_nonce: "fake-valid-country-of-issuance-usa-nonce", customer_id: customer.customer.id
        })

        payment_source.update!(token: method.payment_method.token)
      end

      it "delegates to the braintree payment method" do
        method = braintree_client.payment_method.find(payment_source.token)
        expect(subject).to eql(method.bin)
      end
    end

    context 'when the source token is not known at Braintree' do
      include_context 'with unknown source token'

      it { is_expected.to be_nil }
    end

    context 'when the source token is nil' do
      include_context 'with nil source token'

      it { is_expected.to be_nil }
    end
  end

  describe '#display_payment_type' do
    subject { described_class.new(payment_type: type).display_payment_type }

    context 'when type is CreditCard' do
      let(:type) { 'CreditCard' }

      it 'returns "Payment Type: Credit Card' do
        expect(subject).to eq('Payment Type: Credit Card')
      end
    end

    context 'when type is PayPalAccount' do
      let(:type) { 'PayPalAccount' }

      it 'returns "Payment Type: PayPal' do
        expect(subject).to eq('Payment Type: PayPal')
      end
    end

    context 'when type is VenmoAccount' do
      let(:type) { 'VenmoAccount' }

      it 'returns "Payment Type: Venmo' do
        expect(subject).to eq('Payment Type: Venmo')
      end
    end
  end

  describe '#reusable?' do
    subject { payment_source.reusable? }

    let(:payment_source) { described_class.new(token: token, nonce: nonce) }
    let(:nonce) { 'nonce67890' }

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
