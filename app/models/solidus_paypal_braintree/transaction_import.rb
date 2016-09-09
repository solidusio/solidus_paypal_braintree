require 'active_model'

module SolidusPaypalBraintree

  class TransactionImport
    attr_reader :transaction, :order

    def initialize(order, transaction)
      @order = order
      @transaction = transaction
    end

    def source
      SolidusPaypalBraintree::Source.new nonce: transaction.nonce,
        user: user
    end

    def user
      order.user
    end

    def import!
      order.payments.new source: source,
        payment_method: transaction.payment_method,
        amount: order.total

      order.save!

      advance_order
    end

    protected
    def advance_order
      until order.state == "confirm" do
        order.next!
      end
    end
  end
end
