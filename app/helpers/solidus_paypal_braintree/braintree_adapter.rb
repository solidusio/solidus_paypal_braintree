module SolidusPaypalBraintree
  module BraintreeAdapter
    def self.all_transactions
      Braintree::Transaction.search
    end

    def self.transaction_by_id(id)
      Braintree::Transaction.search { |search| search.id.is id }
    end
  end
end
