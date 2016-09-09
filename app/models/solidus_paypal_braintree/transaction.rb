require 'active_model'

module SolidusPaypalBraintree
  class Transaction
    include ActiveModel::Model

    attr_accessor :nonce, :payment_method

    validates :nonce, presence: true
    validates :payment_method, presence: true

    validate do
      unless payment_method.is_a? SolidusPaypalBraintree::Gateway
        errors.add(:payment_method, 'Must be braintree')
      end
    end

  end
end
