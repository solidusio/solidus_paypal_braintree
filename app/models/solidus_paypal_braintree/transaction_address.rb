require 'active_model'

module SolidusPaypalBraintree
  class TransactionAddress
    include ActiveModel::Model
    include ActiveModel::Validations::Callbacks

    attr_accessor :country_code, :last_name, :first_name,
      :city, :zip, :state_code, :address_line_1, :address_line_2

    validates :first_name, :last_name, :address_line_1, :city, :zip,
      :state_code, presence: true

    before_validation do
      self.country_code = country_code.presence || "us"
    end
  end
end
