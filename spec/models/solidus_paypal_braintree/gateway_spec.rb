require 'spec_helper'
require 'webmock'

RSpec.describe SolidusPaypalBraintree::Gateway do
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
      expect(purchase.success?).to be true
      expect(purchase.message).to eq 'settling'
      expect(purchase.authorization).to be_present
      expect(purchase.test).to be true
    end
  end

  describe 'making a payment on an order' do
    let!(:country) { create :country }

    let(:user) { create :user }
    let(:line_item) { create :line_item, price: 50 }
    let(:address) { create :address, country: country }

    before do
      create :shipping_method, cost: 5
    end

    let(:order) do
      order = Spree::Order.create!(
        line_items: [line_item],
        email: 'test@example.com',
        bill_address: address,
        ship_address: address,
        user: user
      )

      order.update_totals
      expect(order.state).to eq "cart"

      # push through cart, address and delivery
      # its sadly unsafe to use any reasonable factory here accross
      # supported solidus versions
      order.next!
      order.next!
      order.next!

      expect(order.state).to eq "payment"
      order
    end

    let(:gateway) do
      described_class.create!(
        name: 'Braintree',
        auto_capture: true
      )
    end

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
