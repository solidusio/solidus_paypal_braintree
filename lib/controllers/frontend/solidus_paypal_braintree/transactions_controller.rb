# frozen_string_literal: true

module SolidusPaypalBraintree
  class TransactionsController < ::Spree::StoreController
    class InvalidImportError < StandardError; end

    PERMITTED_BRAINTREE_TRANSACTION_PARAMS = [
      :nonce,
      :payment_type,
      :phone,
      :email,
      { address_attributes: [
        :country_code, :country_name, :name, :city, :zip, :state_code,
        :address_line_1, :address_line_2, :first_name, :last_name
      ] }
    ].freeze

    def create
      transaction = SolidusPaypalBraintree::Transaction.new transaction_params
      import = SolidusPaypalBraintree::TransactionImport.new(current_order, transaction)
      restart_checkout = params[:options] && params[:options][:restart_checkout] == "true"

      respond_to do |format|
        if import.valid?
          import.import!(import_state, restart_checkout: restart_checkout)

          format.html { redirect_to redirect_url(import) }
          format.json { render json: { redirectUrl: redirect_url(import) } }
        else
          status = 422
          format.html { import_error(import) }
          format.json { render json: { errors: import.errors, status: status }, status: status }
        end
      end
    end

    private

    def import_state
      params[:state] || 'confirm'
    end

    def import_error(import)
      raise InvalidImportError,
        "Import invalid: #{import.errors.full_messages.join(', ')}"
    end

    def redirect_url(import)
      if import.order.complete?
        spree.order_url(import.order)
      else
        spree.checkout_state_url(import.order.state)
      end
    end

    def transaction_params
      params.require(:transaction)
        .permit(PERMITTED_BRAINTREE_TRANSACTION_PARAMS)
        .merge({ payment_method: payment_method })
    end

    def payment_method
      SolidusPaypalBraintree::Gateway.find(params[:payment_method_id])
    end
  end
end
