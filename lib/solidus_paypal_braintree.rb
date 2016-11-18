require 'solidus_core'
require 'solidus_paypal_braintree/engine'
require 'solidus_paypal_braintree/country_mapper'

module SolidusPaypalBraintree
  def self.table_name_prefix
    'solidus_paypal_braintree_'
  end
end
