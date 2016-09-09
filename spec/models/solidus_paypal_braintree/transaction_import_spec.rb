require 'spec_helper'

describe SolidusPaypalBraintree::TransactionImport do
  let(:order) { Spree::Order.new }
  let(:transaction) { SolidusPaypalBraintree::Transaction.new nonce: 'abcd1234' }

  describe '#source' do
    subject { described_class.new(order, transaction).source }

    it { is_expected.to be_a SolidusPaypalBraintree::Source }

    it 'takes the nonce from the transaction' do
      expect(subject.nonce).to eq 'abcd1234'
    end

    context 'order has a user' do
      let(:user) { Spree::User.new }
      let(:order) { Spree::Order.new user: user  }

      it 'associates user to the source' do
        expect(subject.user).to eq user
      end
    end
  end

  describe '#user' do
    subject { described_class.new(order, transaction).user }

    it { is_expected.to be_nil }

    context 'when order has a user' do
      let(:user) { Spree::User.new }
      let(:order) { Spree::Order.new user: user }

      it { is_expected.to eq user }
    end
  end

  cassette_options = { cassette_name: "transaction/import" }
  describe '#import!', vcr: cassette_options do
    let(:store) { create :store }
    let(:variant) { create :variant }
    let(:line_item) { Spree::LineItem.new(variant: variant, quantity: 1, price: 10) }
    let(:address) { create :address, country: country }
    let(:order) { Spree::Order.create(store: store, line_items: [line_item], ship_address: address, currency: 'USD', total: 10, email: 'test@example.com') }
    let(:payment_method) { SolidusPaypalBraintree::Gateway.create! name: 'Braintree' }
    let(:country) { create :country }

    let(:transaction) do
      SolidusPaypalBraintree::Transaction.new nonce: 'fake-apple-pay-visa-nonce',
        payment_method: payment_method
    end

    # create a shipping method so we can push through to the end
    before do
      country
      create :shipping_method, cost: 5
    end

    subject { described_class.new(order, transaction).import! }

    it 'advances order to confirm state' do
      subject
      expect(order.state).to eq 'confirm'
    end

    it 'has a payment for the cost of line items + shipment' do
      subject
      expect(order.payments.first.amount).to eq 15
    end

    it 'is complete and capturable', aggregate_failures: true do
      subject
      order.complete

      expect(order).to be_complete
      expect(order.payments.first).to be_pending

      order.payments.first.capture!
      # need to reload, as capture will update the order
      expect(order.reload).to be_paid
    end

  end
end
