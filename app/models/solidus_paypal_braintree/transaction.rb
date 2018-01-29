require 'active_model'

module SolidusPaypalBraintree
  class Transaction
    include ActiveModel::Model

    attr_accessor :nonce, :payment_method, :payment_type, :address, :email, :phone

    validates :nonce, presence: true
    validates :payment_method, presence: true
    validates :payment_type, presence: true
    validates :email, presence: true

    validate do
      unless payment_method.is_a? SolidusPaypalBraintree::Gateway
        errors.add(:payment_method, 'Must be braintree')
      end
      if address && !address.valid?
        address.errors.each do |field, error|
          errors.add(:address, "#{field} #{error}")
        end
      end
    end

    def address_attributes=(attributes)
      self.address = TransactionAddress.new attributes
    end
  end
end
