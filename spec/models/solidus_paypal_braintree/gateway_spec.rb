require 'spec_helper'
require 'webmock'
require 'support/order_ready_for_payment'

vcr_options = {
  cassette_name: "solidus_paypal_braintree_gateway",
  match_requests_on: [:method, :uri, :body],
  record: :new_episodes
}

RSpec.describe SolidusPaypalBraintree::Gateway, vcr: vcr_options do
  let(:source) do
    SolidusPaypalBraintree::Source.new(
      nonce: 'fake-paypal-future-nonce'
    )
  end

  let(:gateway) do
    described_class.new
  end

  describe '#purchase' do
    subject(:purchase) { gateway.purchase(10.00, source, {}) }

    it 'returns a successful billing response', aggregate_failures: true do
      expect(purchase).to be_a ActiveMerchant::Billing::Response
      expect(purchase).to be_success
      expect(purchase).to be_test
      expect(purchase.message).to eq 'settling'
      expect(purchase.authorization).to be_present
    end
  end

  describe 'making a payment on an order' do
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

  describe '.generate_token', :braintree_integration do
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
