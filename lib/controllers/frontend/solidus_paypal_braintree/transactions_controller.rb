class SolidusPaypalBraintree::TransactionsController < Spree::StoreController
  class InvalidTransactionError < StandardError; end

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

    respond_to do |format|
      if transaction.valid?
        import = SolidusPaypalBraintree::TransactionImport.new(current_order, transaction)
        import.import!

        format.html { redirect_after_import(import) }
        format.json { head :ok }
      else
        status = 422
        format.html { transaction_error(transaction) }
        format.json {  render json: { errors: transaction.errors, status: status }, status: status }
      end
    end
  end

  private

  def transaction_error(transaction)
    raise InvalidTransactionError,
      "Transaction invalid: #{transaction.errors.full_messages.join(', ')}"
  end

  def redirect_after_import(import)
    if import.order.complete?
      return redirect_to spree.order_path(import.order)
    else
      return redirect_to spree.checkout_state_path(import.order.state)
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
