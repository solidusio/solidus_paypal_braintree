require 'spec_helper'

describe SolidusPaypalBraintree::ClientTokensController do
  routes { SolidusPaypalBraintree::Engine.routes }

  cassette_options = { cassette_name: "braintree/token" }
  describe "POST create", vcr: cassette_options do
    let!(:gateway) { create_gateway }
    let(:user) { create(:user) }
    let(:json) { JSON.parse(response.body) }

    before { user.generate_spree_api_key! }

    context 'without a payment method id' do
      subject(:response) do
        post :create, params: { token: user.spree_api_key }
      end

      it "returns a client token", aggregate_failures: true do
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include 'application/json'
        expect(json["client_token"]).to be_present
        expect(json["client_token"]).to be_a String
        expect(json["payment_method_id"]).to eq gateway.id
      end

      context "when there's two gateway's for different stores" do
        let!(:store1) { create(:store, code: 'store_1') }
        let!(:store2) { create(:store, code: 'store_2') }
        let!(:gateway_for_store1) { create_gateway.tap{ |gw| store1.payment_methods << gw } }
        let!(:gateway_for_store2) { create_gateway.tap{ |gw| store2.payment_methods << gw } }

        it "returns the correct gateway for store1" do
          allow_any_instance_of(described_class).to receive(:current_store).and_return store1
          expect(json["payment_method_id"]).to eq gateway_for_store1.id
        end

        it "returns the correct gateway for store1" do
          allow_any_instance_of(described_class).to receive(:current_store).and_return store2
          expect(json["payment_method_id"]).to eq gateway_for_store2.id
        end
      end
    end

    context 'with a payment method id' do
      subject(:response) do
        post :create, params: { token: user.spree_api_key, payment_method_id: gateway.id }
      end

      it 'uses the selected gateway' do
        expect(json["payment_method_id"]).to eq gateway.id
      end
    end
  end
end
