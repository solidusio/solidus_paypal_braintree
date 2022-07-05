require 'spec_helper'

describe Spree::Api::OrdersController, type: :request do
  stub_authorization!

  describe 'get show' do
    let(:gateway) { create_gateway }
    let(:order) { create(:order_with_line_items) }
    let(:source) do
      SolidusPaypalBraintree::Source.new(
        nonce: 'fake-valid-nonce',
        user: order.user,
        payment_type: SolidusPaypalBraintree::Source::PAYPAL,
        payment_method: gateway
      )
    end

    context 'when using braintree as the payment' do
      before do
        allow_any_instance_of(Spree::Payment).to receive(:create_payment_profile).and_return(true)

        order.payments.create!(
          payment_method: gateway,
          source: source,
          amount: 55
        )
      end

      it "can be rendered correctly" do
        get "/api/orders/#{order.number}"

        expect(response).to have_http_status :ok
      end
    end
  end
end
