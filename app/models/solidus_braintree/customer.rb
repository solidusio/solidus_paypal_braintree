# frozen_string_literal: true

module SolidusPaypalBraintree
  class Customer < ApplicationRecord
    belongs_to :user, class_name: ::Spree::UserClassHandle.new, optional: true
    has_many :sources, class_name: "SolidusPaypalBraintree::Source", inverse_of: :customer, dependent: :destroy
  end
end
