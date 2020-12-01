# frozen_string_literal: true

module SolidusPaypalBraintree
  class ClientTokensController < ::Spree::Api::BaseController
    skip_before_action :authenticate_user

    before_action :load_gateway

    def create
      token = @gateway.generate_token
      if token
        render json: { client_token: token, payment_method_id: @gateway.id }
      else
        render json: { error: Gateway::TOKEN_GENERATION_DISABLED_MESSAGE }, status: :unprocessable_entity
      end
    end

    private

    def load_gateway
      if params[:payment_method_id]
        @gateway = ::SolidusPaypalBraintree::Gateway.find(params[:payment_method_id])
      else
        store_payment_methods_scope =
          if current_store.payment_methods.empty?
            ::SolidusPaypalBraintree::Gateway.all
          else
            ::SolidusPaypalBraintree::Gateway.where(id: current_store.payment_method_ids)
          end
        @gateway = ::SolidusPaypalBraintree::Gateway.where(active: true).merge(store_payment_methods_scope).first!
      end
    end

    def generate_token
      @gateway.generate_token
    rescue ::SolidusPaypalBraintree::Gateway::TokenGenerationDisabledError => e
      Rails.logger.error e
      nil
    end
  end
end
