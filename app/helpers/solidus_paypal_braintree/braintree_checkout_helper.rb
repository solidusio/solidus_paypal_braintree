# frozen_string_literal: true

module SolidusPaypalBraintree
  module BraintreeCheckoutHelper
    def braintree_3ds_options_for(order)
      ship_address = SolidusPaypalBraintree::Address.new(order.ship_address)
      bill_address = SolidusPaypalBraintree::Address.new(order.bill_address)
      {
        nonce: nil, # populated after tokenization
        bin: nil, # populated after tokenization
        onLookupComplete: nil, # populated after tokenization
        amount: order.total,
        email: order.email,
        billingAddress: {
          givenName: bill_address.firstname,
          surname: bill_address.lastname,
          phoneNumber: bill_address.phone,
          streetAddress: bill_address.address1,
          extendedAddress: bill_address.address2,
          locality: bill_address.city,
          region: bill_address.state&.abbr,
          postalCode: bill_address.zipcode,
          countryCodeAlpha2: bill_address.country&.iso,
        },
        additionalInformation: {
          shippingGivenName: ship_address.firstname,
          shippingSurname: ship_address.lastname,
          shippingPhone: ship_address.phone,
          shippingAddress: {
            streedAddress: ship_address.address1,
            extendedAddress: ship_address.address2,
            locality: ship_address.city,
            region: ship_address.state&.abbr,
            postalCode: ship_address.zipcode,
            countryCodeAlpha2: ship_address.country&.iso,
          }
        }
      }
    end

    def paypal_button_preference(key, store:)
      store.braintree_configuration.preferences[key]
    end

    def venmo_button_style(store)
      configuration = store.braintree_configuration
      color = configuration.preferred_venmo_button_color
      width = configuration.preferred_venmo_button_width

      { width: width, color: color }
    end

    def venmo_button_asset_url(style, active: false)
      prefix = 'solidus_paypal_braintree/venmo/venmo_'
      active_string = active ? 'active_' : ''
      path = "#{prefix}#{active_string}#{style[:color]}_button_#{style[:width]}x48.svg"
      asset_path(path)
    end
  end
end
