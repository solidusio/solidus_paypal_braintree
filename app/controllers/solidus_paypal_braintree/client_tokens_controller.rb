module SolidusPaypalBraintree
  class ClientTokensController < Spree::BaseController
    before_action :load_gateway

    def create
      render json: { client_token: generate_token, payment_method_id: @gateway.id }
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

    def generate_token
      options = {}
      options[:customer_id] = customer_id if customer_id.present?

      @gateway.generate_token(options)
    rescue ::SolidusPaypalBraintree::Gateway::TokenGenerationDisabledError => error
      Rails.logger.error error
      nil
    end

    def customer_id
      return unless try_spree_current_user&.braintree_customer
      try_spree_current_user.braintree_customer.braintree_customer_id
    end
  end
end
