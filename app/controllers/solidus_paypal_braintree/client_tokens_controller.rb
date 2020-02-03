module SolidusPaypalBraintree
  class ClientTokensController < ::Spree::Api::BaseController
    skip_before_action :authenticate_user

    before_action :load_gateway

    def create
      render json: { client_token: @gateway.generate_token, payment_method_id: @gateway.id }
    end

    private

    def load_gateway
      if params[:payment_method_id]
        @gateway = ::SolidusPaypalBraintree::Gateway.find_by!(id: params[:payment_method_id])
      else
        store_payment_methods_scope = current_store.payment_methods.empty? ? ::SolidusPaypalBraintree::Gateway.all : ::SolidusPaypalBraintree::Gateway.where(id: current_store.payment_method_ids)
        @gateway = ::SolidusPaypalBraintree::Gateway.where(active: true).merge(store_payment_methods_scope).first!
      end
    end
  end
end
