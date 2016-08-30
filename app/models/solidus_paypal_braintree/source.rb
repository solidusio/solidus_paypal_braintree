class SolidusPaypalBraintree::Source < ApplicationRecord
  belongs_to :payment_method, class_name: 'Spree::PaymentMethod'
end
