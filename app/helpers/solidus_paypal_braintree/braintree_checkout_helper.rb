# frozen_string_literal: true

module SolidusPaypalBraintree
  module BraintreeCheckoutHelper
    def braintree_3ds_options_for(order)
      ship_address = order.ship_address
      bill_address = order.bill_address

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
          region: bill_address.state&.name,
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
            region: ship_address.state&.name,
            postalCode: ship_address.zipcode,
            countryCodeAlpha2: ship_address.country&.iso,
          }
        }
      }
    end

    def paypal_button_preference(key, store:)
      store.braintree_configuration.preferences[key]
    end
  end
end
