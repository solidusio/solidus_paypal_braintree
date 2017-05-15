require 'spec_helper'
require 'webmock'
require 'support/order_ready_for_payment'

RSpec.describe SolidusPaypalBraintree::Gateway do
  let(:gateway) do
    new_gateway.tap(&:save)
  end

  let(:braintree) { gateway.braintree }

  let(:user) { create :user }

  let(:source) do
    SolidusPaypalBraintree::Source.new(
      nonce: 'fake-valid-nonce',
      user: user,
      payment_type: payment_type,
      payment_method: gateway
    )
  end

  let(:payment_type) { SolidusPaypalBraintree::Source::PAYPAL }

  describe "saving preference hashes as strings" do
    subject { gateway.update(update_params) }

    context "with valid hash syntax" do
      let(:update_params) do
        {
          preferred_merchant_currency_map: '{"EUR" => "test_merchant_account_id"}',
          preferred_paypal_payee_email_map: '{"CAD" => "bruce+wayne@example.com"}'
        }
      end

      it "successfully updates the preference" do
        subject
        expect(gateway.preferred_merchant_currency_map).to eq({ "EUR" => "test_merchant_account_id" })
        expect(gateway.preferred_paypal_payee_email_map).to eq({ "CAD" => "bruce+wayne@example.com" })
      end
    end

    context "with invalid user input" do
      let(:update_params) do
        { preferred_merchant_currency_map: '{this_is_not_a_valid_hash}' }
      end

      it "raise a JSON parser error" do
        expect{ subject }.to raise_error(JSON::ParserError)
      end
    end
  end

  describe 'making a payment on an order', vcr: { cassette_name: 'gateway/complete' } do
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
      order.payments.reset

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

    let(:currency) { 'USD' }

    let(:gateway_options) do
      {
        currency: currency,
        shipping_address: {
          name: "Bruce Wayne",
          address1: "42 Spruce Lane",
          address2: "Apt 312",
          city: "Gotham",
          state: "CA",
          zip: "90210",
          country: "US"
        },
        billing_address: {
          name: "Dick Grayson",
          address1: "15 Robin Walk",
          address2: "Apt 123",
          city: "Blüdhaven",
          state: "CA",
          zip: "90210",
          country: "US"
        }
      }
    end

    describe "#method_type" do
      subject { gateway.method_type }
      it { is_expected.to eq "paypal_braintree" }
    end

    describe '#purchase', vcr: { cassette_name: 'gateway/purchase' } do
      subject(:purchase) { gateway.purchase(1000, source, gateway_options) }

      include_examples "successful response"

      it 'submits the transaction for settlement', aggregate_failures: true do
        expect(purchase.message).to eq 'submitted_for_settlement'
        expect(purchase.authorization).to be_present
      end
    end

    describe "#authorize" do
      subject(:authorize) { gateway.authorize(1000, source, gateway_options) }

      context 'successful authorization', vcr: { cassette_name: 'gateway/authorize' } do
        include_examples "successful response"

        it 'passes "Solidus" as the channel parameter in the request' do
          expect_any_instance_of(Braintree::TransactionGateway).
            to receive(:sale).
            with(hash_including({ channel: "Solidus" })).and_call_original
          authorize
        end

        it 'authorizes the transaction', aggregate_failures: true do
          expect(authorize.message).to eq 'authorized'
          expect(authorize.authorization).to be_present
        end
      end

      context 'different merchant account for currency', vcr: { cassette_name: 'gateway/authorize/merchant_account/EUR' } do
        let(:currency) { 'EUR' }

        it 'settles with the correct currency' do
          transaction = braintree.transaction.find(authorize.authorization)
          expect(transaction.merchant_account_id).to eq 'stembolt_EUR'
        end
      end

      context 'different paypal payee email for currency', vcr: { cassette_name: 'gateway/authorize/paypal/EUR' } do
        let(:currency) { 'EUR' }

        it 'uses the correct payee email' do
          expect_any_instance_of(Braintree::TransactionGateway).
            to receive(:sale).
            with(hash_including({
              options: {
                store_in_vault_on_success: true,
                paypal: {
                  payee_email: 'paypal+europe@example.com'
                }
              }
          })).and_call_original
          authorize
        end

        context "PayPal transaction", vcr: { cassette_name: 'gateway/authorize/paypal/address' } do
          it 'includes the shipping address in the request' do
            expect_any_instance_of(Braintree::TransactionGateway).
              to receive(:sale).
              with(hash_including({
                shipping: {
                  first_name: "Bruce",
                  last_name: "Wayne",
                  street_address: "42 Spruce Lane Apt 312",
                  locality: "Gotham",
                  postal_code: "90210",
                  region: "CA",
                  country_code_alpha2: "US"
                }
              })).and_call_original
            authorize
          end
        end
      end

      context "CreditCard transaction", vcr: { cassette_name: 'gateway/authorize/credit_card/address' } do
        let(:payment_type) { SolidusPaypalBraintree::Source::CREDIT_CARD }

        it 'includes the billing address in the request' do
          expect_any_instance_of(Braintree::TransactionGateway).
          to receive(:sale).
          with(hash_including({
            billing: {
              first_name: "Dick",
              last_name: "Grayson",
              street_address: "15 Robin Walk Apt 123",
              locality: "Blüdhaven",
              postal_code: "90210",
              region: "CA",
              country_code_alpha2: "US"
            }
          })).and_call_original
          authorize
        end
      end
    end

    describe "#capture", vcr: { cassette_name: 'gateway/capture' } do
      subject(:capture) { gateway.capture(1000, authorized_id, {}) }

      include_examples "successful response"

      it 'submits the transaction for settlement' do
        expect(capture.message).to eq "submitted_for_settlement"
      end
    end

    describe "#credit", vcr: { cassette_name: 'gateway/credit' } do
      subject(:credit) { gateway.credit(2000, source, settled_id, {}) }

      include_examples "successful response"

      it 'credits the transaction' do
        expect(credit.message).to eq 'submitted_for_settlement'
      end
    end

    describe "#void", vcr: { cassette_name: 'gateway/void' } do
      subject(:void) { gateway.void(authorized_id, source, {}) }

      include_examples "successful response"

      it 'voids the transaction' do
        expect(void.message).to eq 'voided'
      end
    end

    describe "#cancel", vcr: { cassette_name: 'gateway/cancel' } do
      let(:transaction_id) { "fake_transaction_id" }

      subject(:cancel) { gateway.cancel(transaction_id) }

      context "when the transaction is found" do
        context "and it is voidable", vcr: { cassette_name: 'gateway/cancel/void' } do
          let(:transaction_id) { authorized_id }

          include_examples "successful response"

          it 'voids the transaction' do
            expect(cancel.message).to eq 'voided'
          end
        end

        context "and it is not voidable", vcr: { cassette_name: 'gateway/cancel/refunds' } do
          let(:transaction_id) { settled_id }

          include_examples "successful response"

          it 'refunds the transaction' do
            expect(cancel.message).to eq 'submitted_for_settlement'
          end
        end
      end

      context "when the transaction is not found", vcr: { cassette_name: 'gateway/cancel/missing' } do
        it 'raises an error', aggregate_failures: true do
          expect{ cancel }.to raise_error Braintree::NotFoundError
        end
      end
    end

    describe "#create_profile" do
      let(:payment) do
        build(:payment, {
          payment_method: gateway,
          source: source
        })
      end

      subject(:profile) { gateway.create_profile(payment) }

      cassette_options = { cassette_name: "braintree/create_profile" }
      context "with no existing customer profile", vcr: cassette_options do
        it 'creates and returns a new customer profile', aggregate_failures: true do
          expect(profile).to be_a SolidusPaypalBraintree::Customer
          expect(profile.sources).to eq [source]
          expect(profile.braintree_customer_id).to be_present
        end

        it "sets a token on the payment source" do
          expect{ subject }.to change{ source.token }
        end
      end

      context "when the source already has a token" do
        before { source.token = "totally-a-valid-token" }

        it "does not create a new customer profile" do
          expect(profile).to be_nil
        end
      end

      context "when the source already has a customer" do
        before { source.build_customer }

        it "does not create a new customer profile" do
          expect(profile).to be_nil
        end
      end

      context "when the source has no nonce" do
        before { source.nonce = nil }

        it "does not create a new customer profile" do
          expect(profile).to be_nil
        end
      end
    end

    shared_examples "sources_by_order" do
      let(:order) { FactoryGirl.create :order, user: user, state: "complete", completed_at: DateTime.current }
      let(:gateway) { new_gateway.tap(&:save!) }

      let(:other_payment_method) { FactoryGirl.create(:payment_method) }

      let(:source_without_profile) do
        SolidusPaypalBraintree::Source.create!(
          payment_method_id: gateway.id,
          payment_type: payment_type,
          user_id: user.id
        )
      end

      let(:source_with_profile) do
        SolidusPaypalBraintree::Source.create!(
          payment_method_id: gateway.id,
          payment_type: payment_type,
          user_id: user.id
        ).tap do |source|
          source.create_customer!(user: user)
          source.save!
        end
      end

      let!(:source_payment) { FactoryGirl.create(:payment, order: order, payment_method_id: payment_method_id, source: source) }

      context "when the order has payments with the braintree payment method" do
        let(:payment_method_id) { gateway.id }

        context "when the payment has a saved source with a profile" do
          let(:source) { source_with_profile }

          it "returns the source" do
            expect(subject.to_a).to eql([source])
          end
        end

        context "when the payment has a saved source without a profile" do
          let(:source) { source_without_profile }

          it "returns no result" do
            expect(subject.to_a).to eql([])
          end
        end
      end

      context "when the order has no payments with the braintree payment method" do
        let(:payment_method_id) { other_payment_method.id }
        let(:source) { FactoryGirl.create :credit_card }

        it "returns no results" do
          expect(subject.to_a).to eql([])
        end
      end
    end

    describe "#sources_by_order" do
      let(:gateway) { new_gateway.tap(&:save!) }
      let(:order) { FactoryGirl.create :order, user: user, state: "complete", completed_at: DateTime.current }

      subject { gateway.sources_by_order(order) }

      include_examples "sources_by_order"
    end

    describe "#reusable_sources" do
      let(:order) { FactoryGirl.build :order, user: user }
      let(:gateway) { new_gateway.tap(&:save!) }

      subject { gateway.reusable_sources(order) }

      context "when an order is completed" do
        include_examples "sources_by_order"
      end

      context "when an order is not completed" do
        context "when the order has a user id" do
          let(:user) { FactoryGirl.create(:user) }

          let!(:source_without_profile) do
            SolidusPaypalBraintree::Source.create!(
              payment_method_id: gateway.id,
              payment_type: payment_type,
              user_id: user.id
            )
          end

          let!(:source_with_profile) do
            SolidusPaypalBraintree::Source.create!(
              payment_method_id: gateway.id,
              payment_type: payment_type,
              user_id: user.id
            ).tap do |source|
              source.create_customer!(user: user)
              source.save!
            end
          end

          it "includes saved sources with payment profiles" do
            expect(subject).to include(source_with_profile)
          end

          it "excludes saved sources without payment profiles" do
            expect(subject).to_not include(source_without_profile)
          end
        end

        context "when the order does not have a user" do
          let(:user) { nil }
          it "returns no sources for guest users" do
            expect(subject).to eql([])
          end
        end
      end
    end
  end

  describe '.generate_token' do
    subject { gateway.generate_token }

    context 'connection enabled', vcr: { cassette_name: 'braintree/generate_token' } do
      it { is_expected.to be_a(String).and be_present }
    end

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
