require 'spec_helper'

describe SolidusPaypalBraintree::TransactionImport do
  let(:order) { Spree::Order.new }
  let(:transaction_address) { nil }
  let(:transaction) do
    SolidusPaypalBraintree::Transaction.new nonce: 'abcd1234',
      payment_type: "ApplePayCard", address: transaction_address
  end

  describe "#valid?" do
    subject { described_class.new(order, transaction).valid? }

    it { is_expected.to be true }

    context "invalid address" do
      let(:transaction_address) { SolidusPaypalBraintree::TransactionAddress.new }

      it { is_expected.to be false }
    end
  end

  describe '#source' do
    subject { described_class.new(order, transaction).source }

    it { is_expected.to be_a SolidusPaypalBraintree::Source }

    it 'takes the nonce from the transaction' do
      expect(subject.nonce).to eq 'abcd1234'
    end

    it 'takes the payment type from the transaction' do
      expect(subject.payment_type).to eq 'ApplePayCard'
    end

    context 'order has a user' do
      let(:user) { Spree::User.new }
      let(:order) { Spree::Order.new user: user }

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
    let(:order) { Spree::Order.create(number: "R999999999", store: store, line_items: [line_item], ship_address: address, currency: 'USD', total: 10, email: 'test@example.com') }
    let(:payment_method) { create_gateway }
    let(:country) { create :country, iso: 'US', states_required: true }
    let(:transaction_address) { nil }

    let(:transaction) do
      SolidusPaypalBraintree::Transaction.new nonce: 'fake-apple-pay-visa-nonce',
        payment_method: payment_method, address: transaction_address,
        phone: '123-456-7890', email: 'user@example.com'
    end

    before do
      # create a shipping method so we can push through to the end
      country
      create :shipping_method, cost: 5

      # ensure payments have the same number so VCR matches the request body
      allow_any_instance_of(Spree::Payment).
        to receive(:generate_identifier).
        and_return("ABCD1234")
    end

    subject { described_class.new(order, transaction).import! }

    context "passes validation" do
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

      context 'transaction has address' do
        let!(:new_york) { create :state, country: country, abbr: 'NY' }

        let(:transaction_address) do
          SolidusPaypalBraintree::TransactionAddress.new country_code: 'US',
            last_name: 'Venture', first_name: 'Thaddeus', city: 'New York',
            state_code: 'NY', address_line_1: '350 5th Ave', zip: '10118'
        end

        it 'uses the new address', aggregate_failures: true do
          subject
          expect(order.shipping_address.address1).to eq '350 5th Ave'
          expect(order.shipping_address.country).to eq country
          expect(order.shipping_address.state).to eq new_york
        end

        context 'with a tax category' do
          before do
            zone = Spree::Zone.create name: 'nyc tax'
            zone.members << Spree::ZoneMember.new(zoneable: new_york)
            create :tax_rate, zone: zone
          end

          it 'includes the tax in the payment' do
            subject
            expect(order.payments.first.amount).to eq 16
          end
        end
      end
    end

    context "validation fails" do
      let(:transaction_address) do
        SolidusPaypalBraintree::TransactionAddress.new country_code: 'US',
          last_name: 'Venture', first_name: 'Thaddeus', city: 'New York',
          state_code: 'NY', address_line_1: '350 5th Ave'
      end

      it "raises an error with the validation messages" do
        expect { subject }.to raise_error(
          SolidusPaypalBraintree::TransactionImport::InvalidImportError,
          "Validation failed: Transactionaddress zip can't be blank"
        )
      end
    end
  end
end
