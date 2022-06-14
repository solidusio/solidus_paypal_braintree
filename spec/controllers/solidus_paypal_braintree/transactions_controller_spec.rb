require 'spec_helper'

RSpec.describe SolidusPaypalBraintree::TransactionsController, type: :controller do
  routes { SolidusPaypalBraintree::Engine.routes }

  let!(:country) { create :country }
  let(:line_item) { create :line_item, price: 50 }
  let(:order) do
    Spree::Order.create!(
      line_items: [line_item],
      email: 'test@example.com',
      bill_address: create(:address, country: country),
      ship_address: create(:address, country: country),
      user: create(:user)
    )
  end

  let(:payment_method) { create_gateway }

  before do
    allow(controller).to receive(:spree_current_user) { order.user }
    allow(controller).to receive(:current_order) { order }
    create :shipping_method, cost: 5
    create :state, abbr: "WA", country: country
  end

  cassette_options = {
    cassette_name: "transactions_controller/create",
    match_requests_on: [:braintree_uri]
  }
  describe "POST create", vcr: cassette_options do
    subject(:post_create) { post :create, params: params }

    let!(:country) { create :country, iso: 'US' }

    let(:params) do
      {
        transaction: {
          nonce: "fake-valid-nonce",
          payment_type: SolidusPaypalBraintree::Source::PAYPAL,
          phone: "1112223333",
          email: "batman@example.com",
          address_attributes: {
            name: "Wade Wilson",
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

    before do
      create :state, abbr: "WA", country: country
    end

    context "when import has invalid address" do
      before { params[:transaction][:address_attributes][:city] = nil }

      it "raises a validation error" do
        expect { post_create }.to raise_error(
          SolidusPaypalBraintree::TransactionsController::InvalidImportError,
          "Import invalid: " \
          "Address is invalid, " \
          "Address City can't be blank"
        )
      end
    end

    context "when the transaction is valid", vcr: {
      cassette_name: 'transaction/import/valid',
      match_requests_on: [:braintree_uri]
    } do
      it "imports the payment" do
        expect { post_create }.to change { order.payments.count }.by(1)
        expect(order.payments.first.amount).to eq 55
      end

      context "when no end state is provided" do
        it "advances the order to confirm" do
          post_create
          expect(order).to be_confirm
        end
      end

      context "when end state provided is delivery" do
        let(:params) { super().merge(state: 'delivery') }

        it "advances the order to delivery" do
          post_create
          expect(order).to be_delivery
        end
      end

      context "with provided address" do
        it "creates a new address" do
          # Creating the order also creates 3 addresses, we want to make sure
          # the transaction import only creates 1 new one
          order
          expect { post_create }.to change(Spree::Address, :count).by(1)
          expect(Spree::Address.last.address1).to eq "123 Fake Street"
        end
      end

      context "without country ISO" do
        before do
          params[:transaction][:address_attributes][:country_code] = ""
          params[:transaction][:address_attributes][:country_name] = "United States"
        end

        it "creates a new address, looking up the ISO by country name" do
          order
          expect { post_create }.to change(Spree::Address, :count).by(1)
          expect(Spree::Address.last.country.iso).to eq "US"
        end
      end

      context "without transaction address" do
        before { params[:transaction].delete(:address_attributes) }

        it "does not create a new address" do
          order
          expect { post_create }.not_to(change(Spree::Address, :count))
        end
      end

      context "when format is HTML" do
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

      context "when format is JSON" do
        before { params[:format] = :json }

        it "has a successful response" do
          post_create
          expect(response).to be_successful
        end
      end
    end

    context "when the transaction is invalid" do
      before { params[:transaction][:email] = nil }

      context "when format is HTML" do
        it "raises an error including the validation messages" do
          expect { post_create }.to raise_error(
            SolidusPaypalBraintree::TransactionsController::InvalidImportError,
            "Import invalid: Email can't be blank"
          )
        end
      end

      context "when format is JSON" do
        before { params[:format] = :json }

        it "has a failed status" do
          post_create
          expect(response.status).to eq 422
        end

        it "returns the errors as JSON" do
          post_create
          expect(JSON.parse(response.body)["errors"]["email"]).to eq ["can't be blank"]
        end
      end
    end
  end
end
