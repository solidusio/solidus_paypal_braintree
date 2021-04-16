# frozen_string_literal: true

require 'active_model'

module SolidusPaypalBraintree
  class TransactionAddress
    include ActiveModel::Model
    include ActiveModel::Validations::Callbacks
    include SolidusPaypalBraintree::CountryMapper

    attr_accessor :country_code, :name, :city, :zip, :state_code,
      :address_line_1, :address_line_2, :first_name, :last_name

    validates :address_line_1, :city, :zip, :country_code, presence: true
    validates :name, presence: true, unless: ->(address){ address.first_name.present? }

    before_validation do
      self.country_code = country_code.presence || "us"
    end

    validates :spree_country, presence: true
    validates :state_code, :spree_state, presence: true, if: :should_match_state_model?

    def self.split_name(name)
      if defined?(Spree::Address::Name)
        address_name = Spree::Address::Name.new(name)
        [address_name.first_name, address_name.last_name]
      else
        name.strip.split(' ', 2)
      end
    end

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
      spree_country && state_code && ( @state ||= spree_country.states.find_by(
        ::Spree::State.arel_table[:name].matches(state_code).or(
          ::Spree::State.arel_table[:abbr].matches(state_code)
        )
      ))
    end

    def to_spree_address
      address = ::Spree::Address.new(
        city: city,
        country: spree_country,
        address1: address_line_1,
        address2: address_line_2,
        zipcode: zip
      )

      if SolidusSupport.combined_first_and_last_name_in_address?
        address.name = begin
          if first_name.nil?
            name
          else
            [first_name, last_name].join(" ")
          end
        end
      else
        ::Spree::Deprecation.warn("first_name and last_name are deprecated. Use name instead.", caller)
        if first_name.nil?
          first, last = self.class.split(name)
          address.firstname = first
          address.lastname = last || "(left blank)"
        else
          address.firstname = first_name
          address.lastname = last_name || "(left blank)"
        end
      end

      if spree_state
        address.state = spree_state
      else
        address.state_name = state_code
      end
      address
    end

    # Check to see if this address should match to a state model in the database
    def should_match_state_model?
      spree_country&.states_required?
    end
  end
end
