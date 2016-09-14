require 'spec_helper'

RSpec.describe SolidusPaypalBraintree::TransactionsController, type: :controller do
  include_context "order ready for payment"

  let(:payment_method) { create_gateway }

  before do
    allow(controller).to receive(:spree_current_user) { user }
    allow(controller).to receive(:current_order) { order }
  end

  cassette_options = { cassette_name: "transactions_controller/create" }
  describe "POST create", vcr: cassette_options do
    subject(:post_create) { post :create, params }

    let(:params) do
      {
        transaction: {
          nonce: "ABC123",
          payment_type: "MonopolyMoney",
          phone: "1112223333",
          email: "batman@example.com",
          address_attributes: {
            first_name: "Wade",
            last_name: "Wilson",
            address_line_1: "123 Fake Street",
            city: "Seattle",
            zip: "98101",
            state_code: "WA",
            country_code: "US"
          }
        },
        payment_method_id: payment_method.id
      }
    end

    context "when the transaction is valid" do
      it "imports the payment" do
        expect { post_create }.to change { order.payments.count }.by(1)
        expect(order.payments.first.amount).to eq 55
      end

      context "and an address is provided" do
        it "creates a new address" do
          # Creating the order also creates 3 addresses, we want to make sure
          # the transaction import only creates 1 new one
          order
          expect { post_create }.to change { Spree::Address.count }.by(1)
          expect(Spree::Address.last.full_name).to eq "Wade Wilson"
        end
      end

      context "and the transaction does not have an address" do
        before { params[:transaction].delete(:address_attributes) }

        it "does not create a new address" do
          order
          expect { post_create }.to_not change { Spree::Address.count }
        end
      end

      context "when import! leaves the order in confirm" do
        it "redirects the user to the confirm page" do
          expect(post_create).to redirect_to spree.checkout_state_path("confirm")
        end
      end

      context "when import! completes the order" do
        before { allow(order).to receive(:complete?).and_return(true) }

        it "displays the order to the user" do
          expect(post_create).to redirect_to spree.order_path(order)
        end
      end
    end

    context "when the transaction is invalid" do
      before { params[:transaction].delete(:phone) }

      it "raises an error" do
        expect { post_create }.to raise_error(
          SolidusPaypalBraintree::TransactionsController::InvalidTransactionError,
          "Transaction invalid: Phone can't be blank"
        )
      end
    end
  end
end
