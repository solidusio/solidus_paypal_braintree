# frozen_string_literal: true

FactoryBot.define do
  # Define your Spree extensions Factories within this file to enable applications,
  # and other extensions to use and override them.
  #
  # Example adding this to your spec_helper will load these Factories for use:
  # require 'solidus_paypal_braintree/factories'

  factory :solidus_paypal_braintree_payment_method, class: SolidusPaypalBraintree::Gateway do
    name 'Solidus PayPal Braintree Gateway'
    active true
  end

  factory :solidus_paypal_braintree_source, class: SolidusPaypalBraintree::Source do
    association(:payment_method, factory: :solidus_paypal_braintree_payment_method)
    user

    trait :credit_card do
      payment_type SolidusPaypalBraintree::Source::CREDIT_CARD
    end

    trait :paypal do
      payment_type SolidusPaypalBraintree::Source::PAYPAL
    end

    trait :apple_pay do
      payment_type SolidusPaypalBraintree::Source::APPLE_PAY
    end
  end
end

FactoryBot.modify do
  # The Solidus address factory randomizes the zipcode.
  # The OrderWalkThrough we use in the credit card checkout spec uses this factory for the user addresses.
  # For credit card payments we transmit the billing address to braintree, for paypal payments the shipping address.
  # As we match the body in our VCR settings VCR can not match the request anymore and therefore cannot replay existing
  # cassettes.
  #

  factory :address do
    zipcode { '21088-0255' }

    if SolidusSupport.combined_first_and_last_name_in_address?
      transient do
        firstname { "John" }
        lastname { "Doe" }
      end

      name { "#{firstname} #{lastname}" }
    end
  end
end
