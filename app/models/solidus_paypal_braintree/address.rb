module SolidusPaypalBraintree
  class Address
    def initialize(spree_address)
      @spree_address = spree_address
    end

    def to_json
      address_hash = {
        line1: spree_address.address1,
        line2: spree_address.address2,
        city: spree_address.city,
        postalCode: spree_address.zipcode,
        countryCode: spree_address.country.iso,
        phone: spree_address.phone,
        recipientName: spree_address.full_name
      }

      if Spree::Config.address_requires_state && spree_address.country.states_required
        address_hash[:state] = spree_address.state.name
      end
      address_hash.to_json
    end

    private

    attr_reader :spree_address
  end
end
