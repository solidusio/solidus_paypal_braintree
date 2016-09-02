require 'spec_helper'
require 'webmock'
require 'support/order_ready_for_payment'

RSpec.describe SolidusPaypalBraintree::Gateway do
  let(:source) do
    SolidusPaypalBraintree::Source.new(
      nonce: 'fake-paypal-future-nonce'
    )
  end

  let(:gateway) do
    described_class.new
  end

  cassette_options = { cassette_name: "braintree/purchase" }
  describe '#purchase', vcr: cassette_options do
    subject(:purchase) { gateway.purchase(10.00, source, {}) }

    it 'returns a successful billing response', aggregate_failures: true do
      expect(purchase).to be_a ActiveMerchant::Billing::Response
      expect(purchase).to be_success
      expect(purchase).to be_test
      expect(purchase.message).to eq 'settling'
      expect(purchase.authorization).to be_present
    end
  end

  cassette_options = { cassette_name: "braintree/payment" }
  describe 'making a payment on an order', vcr: cassette_options do
    include_context 'order ready for payment'

    it 'can complete an order' do
      expect(order.total).to eq 55

      payment = order.payments.create!(
        payment_method: gateway,
        source: source,
        amount: 55
      )

      expect(payment.capture_events.count).to eq 0

      order.next!
      expect(order.state).to eq "confirm"

      order.complete!
      expect(order.state).to eq "complete"

      expect(order.outstanding_balance).to eq 0.0

      expect(payment.capture_events.count).to eq 1
    end
  end

  cassette_options = { cassette_name: "braintree/authorize" }
  describe "#authorize", vcr: cassette_options do
    subject(:authorize) do
      gateway.authorize(10.00, source, {})
    end

    it "returns a successful billing response", aggregate_failures: true do
      expect(authorize).to be_a ActiveMerchant::Billing::Response
      expect(authorize).to be_success
      expect(authorize).to be_test
      expect(authorize.message).to eq "authorized"
    end
  end

  cassette_options = { cassette_name: "braintree/void" }
  describe "#void", vcr: cassette_options do
    subject(:void) { gateway.void(response_code, source, {}) }

    let(:response_code) do
      result = Braintree::Transaction.sale(
        amount: 1,
        payment_method_nonce: source.nonce
      )
      result.transaction.id
    end

    it 'returns a successful billing response', aggregate_failures: true do
      expect(void).to be_a ActiveMerchant::Billing::Response
      expect(void).to be_success
      expect(void).to be_test
      expect(void.message).to eq 'voided'
    end
  end

  cassette_options = { cassette_name: "braintree/token" }
  describe '.generate_token', :braintree_integration, vcr: cassette_options do
    subject { gateway.generate_token }

    it { is_expected.to be_a(String).and be_present }

    context 'when token generation is disabled' do
      around do |ex|
        allowed = WebMock.net_connect_allowed?
        WebMock.disable_net_connect!
        ex.run
        WebMock.allow_net_connect! if allowed
      end

      let(:gateway) do
        gateway = described_class.create!(name: 'braintree')
        gateway.preferred_token_generation_enabled = false
        gateway
      end

      it { is_expected.to match(/Token generation is disabled/) }
    end
  end
end
