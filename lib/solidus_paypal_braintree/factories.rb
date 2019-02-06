FactoryBot.define do
  # Define your Spree extensions Factories within this file to enable applications, and other extensions to use and override them.
  #
  # Example adding this to your spec_helper will load these Factories for use:
  # require 'solidus_paypal_braintree/factories'
end

FactoryBot.modify do
  # The Solidus address factory randomizes the zipcode.
  # The OrderWalkThrough we use in the credit card checkout spec uses this factory for the user addresses.
  # For credit card payments we transmit the billing address to braintree, for paypal payments the shipping address.
  # As we match the body in our VCR settings VCR can not match the request anymore and therefore cannot replay existing cassettes.
  #
  factory :address do
    zipcode { '21088-0255' }
    lastname { 'Doe' }
  end
end
