require 'active_model'

module SolidusPaypalBraintree
  class TransactionImport
    class InvalidImportError < StandardError; end

    include ActiveModel::Model

    validate do
      if transaction.address && !transaction.address.valid?
        transaction.address.errors.each do |field, error|
          errors.add("TransactionAddress", "#{field} #{error}")
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
        user: user
    end

    def user
      order.user
    end

    def import!
      if valid?
        order.email = user.try!(:email) || transaction.email

        if address
          order.shipping_address = order.billing_address = address
          # work around a bug in most solidus versions
          # about tax zone cachine between address changes
          order.instance_variable_set("@tax_zone", nil)
          order.next
        end

        if order.checkout_steps.index("payment") > (order.checkout_steps.index(order.state) || 0)
          advance_order "payment"
        end

        order.payments.new source: source,
          payment_method: transaction.payment_method,
          amount: order.total

        order.save!

        advance_order
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

    protected

    def advance_order(state = "confirm")
      order.next! until order.state == state
    end
  end
end
