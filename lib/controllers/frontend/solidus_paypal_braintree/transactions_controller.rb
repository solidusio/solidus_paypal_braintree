class SolidusPaypalBraintree::TransactionsController < Spree::StoreController
  class InvalidImportError < StandardError; end

  PERMITTED_BRAINTREE_TRANSACTION_PARAMS = [
    :nonce,
    :payment_type,
    :phone,
    :email,
    address_attributes: [
      :country_code, :last_name, :first_name,
      :city, :zip, :state_code, :address_line_1, :address_line_2
    ]
  ]

  def create
    transaction = SolidusPaypalBraintree::Transaction.new transaction_params
    import = SolidusPaypalBraintree::TransactionImport.new(current_order, transaction)

    respond_to do |format|
      if import.valid?
        import.import!

        format.html { redirect_after_import(import) }
        format.json { head :ok }
      else
        status = 422
        format.html { import_error(import) }
        format.json { render json: { errors: import.errors, status: status }, status: status }
      end
    end
  end

  private

  def import_error(import)
    raise InvalidImportError,
      "Import invalid: #{import.errors.full_messages.join(', ')}"
  end

  def redirect_after_import(import)
    if import.order.complete?
      redirect_to spree.order_path(import.order)
    else
      redirect_to spree.checkout_state_path(import.order.state)
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
