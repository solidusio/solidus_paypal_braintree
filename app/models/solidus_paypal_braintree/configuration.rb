class SolidusPaypalBraintree::Configuration < ApplicationRecord
  belongs_to :store, class_name: 'Spree::Store'

  validates :store, presence: true
end
