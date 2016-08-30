require 'solidus_core'
require 'solidus_paypal_braintree/engine'

module SolidusPaypalBraintree
  def self.table_name_prefix
    'solidus_paypal_braintree_'
  end
end
