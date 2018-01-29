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
        expect(response.content_type).to eq "application/json"
        expect(json["client_token"]).to be_present
        expect(json["client_token"]).to be_a String
        expect(json["payment_method_id"]).to eq gateway.id
      end

      context "when there's two gateway's for different stores" do
        let!(:store1) { create(:store, code: 'store_1') }
        let!(:store2) { create(:store, code: 'store_2') }

        before do
          create_gateway(id: 10).tap{|gw| store1.payment_methods << gw }
          create_gateway(id: 11).tap{|gw| store2.payment_methods << gw }
        end

        it "returns the correct gateway for store1" do
          allow_any_instance_of(described_class).to receive(:current_store).and_return store1
          expect(json["payment_method_id"]).to eq 10
        end
        it "returns the correct gateway for store1" do
          allow_any_instance_of(described_class).to receive(:current_store).and_return store2
          expect(json["payment_method_id"]).to eq 11
        end
      end
    end

    context 'with a payment method id' do
      before do
        create_gateway id: 3
      end

      subject(:response) do
        post :create, params: { token: user.spree_api_key, payment_method_id: 3 }
      end

      it 'uses the selected gateway' do
        expect(json["payment_method_id"]).to eq 3
      end
    end
  end
end
