module SolidusPaypalBraintree
  class ClientTokensController < Spree::Api::BaseController
    skip_before_action :authenticate_user

    before_action :load_gateway

    def create
      render json: { client_token: @gateway.generate_token, payment_method_id: @gateway.id }
    end

    private

    def load_gateway
      @gateway = ::SolidusPaypalBraintree::Gateway.
        where(active: true).
        find(params[:payment_method_id])
    end
  end
end
