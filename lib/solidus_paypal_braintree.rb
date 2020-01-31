# frozen_string_literal: true

require 'solidus_core'
require 'solidus_paypal_braintree/version'
require 'solidus_paypal_braintree/engine'
require 'solidus_paypal_braintree/country_mapper'
require 'solidus_paypal_braintree/request_protection'
require 'solidus_support'

module SolidusPaypalBraintree
  def self.table_name_prefix
    'solidus_paypal_braintree_'
  end
end
