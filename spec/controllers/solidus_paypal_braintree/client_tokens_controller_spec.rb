require 'spec_helper'

describe SolidusPaypalBraintree::ClientTokensController do
  cassette_options = { cassette_name: "braintree/token" }
  describe "POST create", vcr: cassette_options do
    let!(:gateway) { create_gateway }
    let(:user) { create(:user) }
    let(:json) { JSON.parse(response.body) }

    before { user.generate_spree_api_key! }

    subject(:response) do
      post :create, payment_method_id: gateway.id, token: user.spree_api_key
    end

    it "returns a client token", aggregate_failures: true do
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq "application/json"
      expect(json["client_token"]).to be_present
      expect(json["client_token"]).to be_a String
      expect(json["payment_method_id"]).to eq gateway.id
    end
  end
end
