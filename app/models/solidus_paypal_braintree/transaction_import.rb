require 'active_model'

module SolidusPaypalBraintree
  class TransactionImport
    class InvalidImportError < StandardError; end

    include ActiveModel::Model

    validate do
      errors.add("Address", "is invalid") if address && !address.valid?

      if !transaction.valid?
        transaction.errors.each do |field, error|
          errors.add(field, error)
        end
      end
      errors.none?
    end

    attr_reader :transaction, :order

    def initialize(order, transaction)
      @order = order
      @transaction = transaction
    end

    def source
      SolidusPaypalBraintree::Source.new nonce: transaction.nonce,
        payment_type: transaction.payment_type,
        payment_method: transaction.payment_method,
        user: user
    end

    def user
      order.user
    end

    def import!(end_state, restart_checkout: false)
      if valid?
        order.email = user.try!(:email) || transaction.email

        if address
          order.shipping_address = order.billing_address = address
          # work around a bug in most solidus versions
          # about tax zone cachine between address changes
          order.instance_variable_set("@tax_zone", nil)
        end

        payment = order.payments.new source: source,
          payment_method: transaction.payment_method,
          amount: order.total

        order.save!
        order.restart_checkout_flow if restart_checkout
        advance_order(payment, end_state)
      else
        raise InvalidImportError,
          "Validation failed: #{errors.full_messages.join(', ')}"
      end
    end

    def address
      transaction.address && transaction.address.to_spree_address.tap do |address|
        address.phone = transaction.phone
      end
    end

    def state_before_current?(state)
      steps = order.checkout_steps
      steps.index(state) < (steps.index(order.state) || 0)
    end

    protected

    def advance_order(payment, end_state)
      return if state_before_current?(end_state)

      until order.state == end_state
        order.next!
        update_payment_total(payment) if order.payment?
      end
    end

    def update_payment_total(payment)
      payment_total = order.payments.where(state: %w[checkout pending]).sum(:amount)
      payment_difference = order.outstanding_balance - payment_total

      if payment_difference != 0
        payment.update!(amount: payment.amount + payment_difference)
      end
    end
  end
end
