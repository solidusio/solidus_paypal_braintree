require 'active_model'

module SolidusPaypalBraintree
  class TransactionAddress
    include ActiveModel::Model
    include ActiveModel::Validations::Callbacks

    attr_accessor :country_code, :last_name, :first_name,
      :city, :zip, :state_code, :address_line_1, :address_line_2

    validates :first_name, :last_name, :address_line_1, :city, :zip,
      :state_code, :country_code, presence: true

    before_validation do
      self.country_code = country_code.presence || "us"
    end

    validates :spree_country, presence: true
    validates :spree_state, presence: true, if: :should_match_state_model?

    def spree_country
      country_code && (@country ||= Spree::Country.find_by(iso: country_code.upcase))
    end

    def spree_state
      spree_country && state_code && ( @state ||= spree_country.states.where(
        Spree::State.arel_table[:name].matches(state_code).or(
          Spree::State.arel_table[:abbr].matches(state_code)
        )
      ).first )
    end

    # Check to see if this address should match to a state
    #   model in the database.
    def should_match_state_model?
      spree_country.present? && spree_country.states.any?
    end
  end
end
