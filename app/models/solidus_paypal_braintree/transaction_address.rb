require 'active_model'

module SolidusPaypalBraintree
  class TransactionAddress
    include ActiveModel::Model
    include ActiveModel::Validations::Callbacks
    include SolidusPaypalBraintree::CountryMapper

    attr_accessor :country_code, :last_name, :first_name,
      :city, :zip, :state_code, :address_line_1, :address_line_2

    validates :first_name, :last_name, :address_line_1, :city, :zip,
      :country_code, presence: true

    before_validation do
      self.country_code = country_code.presence || "us"
    end

    validates :spree_country, presence: true
    validates :state_code, :spree_state, presence: true, if: :should_match_state_model?

    def initialize(attributes = {})
      country_name = attributes.delete(:country_name) || ""
      if attributes[:country_code].blank?
        attributes[:country_code] = iso_from_name(country_name)
      end

      super(attributes)
    end

    def spree_country
      country_code && (@country ||= ::Spree::Country.find_by(iso: country_code.upcase))
    end

    def spree_state
      spree_country && state_code && ( @state ||= spree_country.states.where(
        ::Spree::State.arel_table[:name].matches(state_code).or(
          ::Spree::State.arel_table[:abbr].matches(state_code)
        )
      ).first )
    end

    def to_spree_address
      address = ::Spree::Address.new first_name: first_name,
        last_name: last_name,
        city: city,
        country: spree_country,
        address1: address_line_1,
        address2: address_line_2,
        zipcode: zip

      if spree_state
        address.state = spree_state
      else
        address.state_name = state_code
      end
      address
    end

    # Check to see if this address should match to a state model in the database
    def should_match_state_model?
      spree_country.try!(:states_required?)
    end
  end
end
