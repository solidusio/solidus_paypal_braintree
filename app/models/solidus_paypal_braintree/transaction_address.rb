require 'active_model'

module SolidusPaypalBraintree
  class TransactionAddress
    include ActiveModel::Model

    attr_accessor :country_code, :last_name, :first_name,
      :city, :zip, :state_code, :address_line_1, :address_line_2

    validates :first_name, :last_name, :address_line_1, :city, :zip,
      :state_code, :country_code, presence: true
  end
end
