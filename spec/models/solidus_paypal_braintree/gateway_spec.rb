require 'spec_helper'
require 'webmock'
require 'support/order_ready_for_payment'

RSpec.describe SolidusPaypalBraintree::Gateway do
  let(:gateway) do
    new_gateway
  end

  let(:braintree) { gateway.braintree }

  let(:user) { create :user }

  let(:source) do
    SolidusPaypalBraintree::Source.new(
      nonce: 'fake-paypal-future-nonce',
      user: user
    )
  end

  cassette_options = { cassette_name: "braintree/payment" }
  describe 'making a payment on an order', vcr: cassette_options do
    include_context 'order ready for payment'

    before do
      order.update(number: "ORDER0")
      payment.update(number: "PAYMENT0")
    end

    let(:payment) do
      order.payments.create!(
        payment_method: gateway,
        source: source,
        amount: 55
      )
    end

    it 'can complete an order' do
      expect(order.total).to eq 55

      expect(payment.capture_events.count).to eq 0

      order.next!
      expect(order.state).to eq "confirm"

      order.complete!
      expect(order.state).to eq "complete"

      expect(order.outstanding_balance).to eq 0.0

      expect(payment.capture_events.count).to eq 1
    end
  end

  describe "instance methods" do
    shared_examples "successful response" do
      it 'returns a successful billing response', aggregate_failures: true do
        expect(subject).to be_a ActiveMerchant::Billing::Response
        expect(subject).to be_success
        expect(subject).to be_test
      end
    end

    let(:authorized_id) do
      braintree.transaction.sale(
        amount: 40,
        payment_method_nonce: source.nonce
      ).transaction.id
    end

    let(:sale_id) do
      braintree.transaction.sale(
        amount: 40,
        payment_method_nonce: source.nonce,
        options: {
          submit_for_settlement: true
        }
      ).transaction.id
    end

    let(:settled_id) do
      braintree.testing.settle(sale_id).transaction.id
    end

    describe "#method_type" do
      subject { gateway.method_type }
      it { is_expected.to eq "paypal_braintree" }
    end

    cassette_options = { cassette_name: "braintree/purchase" }
    describe '#purchase', vcr: cassette_options do
      subject(:purchase) { gateway.purchase(1000, source, {}) }

      include_examples "successful response"

      it 'submits the transaction for settlement', aggregate_failures: true do
        expect(purchase.message).to eq 'settling'
        expect(purchase.authorization).to be_present
      end
    end

    cassette_options = { cassette_name: "braintree/authorize" }
    describe "#authorize", vcr: cassette_options do
      subject(:authorize) { gateway.authorize(1000, source, {}) }

      include_examples "successful response"

      it 'authorizes the transaction', aggregate_failures: true do
        expect(authorize.message).to eq 'authorized'
        expect(authorize.authorization).to be_present
      end
    end

    cassette_options = { cassette_name: "braintree/capture" }
    describe "#capture", vcr: cassette_options do
      subject(:capture) { gateway.capture(1000, authorized_id, {}) }

      include_examples "successful response"

      it 'submits the transaction for settlement' do
        expect(capture.message).to eq "settling"
      end
    end

    cassette_options = { cassette_name: "braintree/credit" }
    describe "#credit", vcr: cassette_options do
      subject(:credit) { gateway.credit(2000, source, settled_id, {}) }

      include_examples "successful response"

      it 'credits the transaction' do
        expect(credit.message).to eq 'settling'
      end
    end

    cassette_options = { cassette_name: "braintree/void" }
    describe "#void", vcr: cassette_options do
      subject(:void) { gateway.void(authorized_id, source, {}) }

      include_examples "successful response"

      it 'voids the transaction' do
        expect(void.message).to eq 'voided'
      end
    end

    describe "#cancel" do
      let(:transaction_id) { "fake_transaction_id" }

      subject(:cancel) { gateway.cancel(transaction_id) }

      context "when the transaction is found" do
        cassette_options = { cassette_name: "braintree/cancel/void" }
        context "and it is voidable", vcr: cassette_options do
          let(:transaction_id) { authorized_id }

          include_examples "successful response"

          it 'voids the transaction' do
            expect(cancel.message).to eq 'voided'
          end
        end

        cassette_options = { cassette_name: "braintree/cancel/refund" }
        context "and it is not voidable", vcr: cassette_options do
          let(:transaction_id) { settled_id }

          include_examples "successful response"

          it 'refunds the transaction' do
            expect(cancel.message).to eq 'settling'
          end
        end
      end

      cassette_options = { cassette_name: "braintree/cancel/not_found" }
      context "when the transaction is not found", vcr: cassette_options do
        it 'raises an error', aggregate_failures: true do
          expect{ cancel }.to raise_error Braintree::NotFoundError
        end
      end
    end

    cassette_options = { cassette_name: "braintree/create_profile" }
    describe "#create_profile", vcr: cassette_options do
      let(:payment) do
        create(:payment, {
          payment_method: gateway,
          source: source
        })
      end

      subject(:profile) { gateway.create_profile(payment) }

      it 'creates and returns a new customer profile', aggregate_failures: true do
        expect(profile).to be_a SolidusPaypalBraintree::Customer
        expect(profile.sources).to eq [source]
        expect(profile.braintree_customer_id).to be_present
      end
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
