# frozen_string_literal: true

require 'active_model'

module SolidusPaypalBraintree
  class Transaction
    include ActiveModel::Model

    attr_accessor :nonce, :payment_method, :payment_type, :paypal_funding_source, :address, :email, :phone

    validates :nonce, presence: true
    validates :payment_method, presence: true
    validates :payment_type, presence: true
    validates :email, presence: true

    validate do
      unless payment_method.is_a? SolidusPaypalBraintree::Gateway
        errors.add(:payment_method, 'Must be braintree')
      end
      if address && !address.valid?
        address.errors.each do |error|
          errors.add(:address, error.full_message)
        end
      end
    end

    def address_attributes=(attributes)
      self.address = TransactionAddress.new attributes
    end
  end
end
