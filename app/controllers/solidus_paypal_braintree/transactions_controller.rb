class SolidusPaypalBraintree::TransactionsController < Spree::StoreController

  PERMITTED_BRAINTREE_TRANSACTION_PARAMS = [
    :nonce,
    :payment_type,
    address_attributes: [
      :country_code, :last_name, :first_name,
      :city, :zip, :state_code, :address_line_1, :address_line_2
    ]
  ]


  def create
    transaction = SolidusPaypalBraintree::Transaction.new transaction_params

    if transaction.valid?
      import = SolidusPaypalBraintree::TransactionImport.new(current_order, transaction)
      import.import!

      if import.order.complete?
        return redirect_to spree.order_path(import.order)
      else
        return redirect_to spree.checkout_state_path(import.order.state)
      end
    else
      render text: transaction.errors
    end
  end

  private
  def transaction_params
    params.require(:transaction)
      .permit(PERMITTED_BRAINTREE_TRANSACTION_PARAMS)
      .merge({ payment_method: payment_method })
  end

  def payment_method
    SolidusPaypalBraintree::Gateway.find(params[:payment_method_id])
  end
end
