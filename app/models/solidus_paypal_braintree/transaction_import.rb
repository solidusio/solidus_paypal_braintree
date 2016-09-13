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
      order.email = user.try!(:email) || transaction.email

      if address
        order.shipping_address = order.billing_address = address
        # work around a bug in most solidus versions
        # about tax zone cachine between address changes
        order.instance_variable_set("@tax_zone", nil)
        order.next
      end

      order.payments.new source: source,
        payment_method: transaction.payment_method,
        amount: order.total

      order.save!

      advance_order
    end

    def address
      transaction.address.try do |ta|
        country = Spree::Country.find_by(iso: ta.country_code.upcase)
        Spree::Address.new first_name: ta.first_name,
          last_name: ta.last_name,
          city: ta.city,
          country: country,
          state_name: ta.state_code,
          address1: ta.address_line_1,
          address2: ta.address_line_2,
          zipcode: ta.zip,
          phone: transaction.phone
      end
    end

    protected

    def advance_order
      order.next! until order.state == "confirm"
    end
  end
end
