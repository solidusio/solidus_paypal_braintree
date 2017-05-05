class SolidusPaypalBraintree::Customer < ApplicationRecord
  belongs_to :user, class_name: Spree::UserClassHandle.new
  has_many :sources, class_name: "SolidusPaypalBraintree::Source", inverse_of: :customer
end
