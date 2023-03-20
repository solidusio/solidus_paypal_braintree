# frozen_string_literal: true

require 'solidus_braintree'
require 'solidus_paypal_braintree/version'
require 'solidus_paypal_braintree/engine'

module SolidusPaypalBraintree
  def self.table_name_prefix
    'solidus_paypal_braintree_'
  end
end
