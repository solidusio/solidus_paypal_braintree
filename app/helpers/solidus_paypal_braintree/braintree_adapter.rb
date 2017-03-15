module SolidusPaypalBraintree
  module BraintreeAdapter
    def self.all_transactions
      Braintree::Transaction.search
    end
  end
end
