require 'spec_helper'
require 'support/order_ready_for_payment'

RSpec.describe SolidusPaypalBraintree::CheckoutsController, type: :controller do
  include_context 'order ready for payment'

  cassette_options = { cassette_name: "checkouts_controller/update" }
  describe 'PATCH update', vcr: cassette_options do
    subject(:patch_update) { patch :update, params }

    let(:params) do
      {
        "state" => "payment",
        "order" => {
          "payments_attributes" => [
            {
              "payment_method_id" => payment_method.id,
              "source_attributes" => {
                "nonce" => "fake-paypal-future-nonce",
                "payment_type" => "PayPal"
              }
            }
          ],
          "use_billing" => "1",
          "use_postmates_shipping" => "0"
        },
        "reuse_credit" => "1",
        "order_bill_address" => "",
        "reuse_bill_address" => "1"
      }
    end

    let!(:payment_method) do
      create_gateway
    end

    before do
      allow(controller).to receive(:try_spree_current_user) { user }
      allow(controller).to receive(:spree_current_user) { user }
      allow(controller).to receive(:current_order) { order }
    end

    it 'create a payment' do
      expect { patch_update }.
        to change { order.payments.count }.
        from(0).
        to(1)
    end

    it 'creates a payment source' do
      expect { patch_update }.
        to change { SolidusPaypalBraintree::Source.count }.
        from(0).
        to(1)
    end

    it 'assigns @order' do
      patch_update
      expect(assigns(:order)).to eq order
    end
  end
end
