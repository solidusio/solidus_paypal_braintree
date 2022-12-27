# frozen_string_literal: true

require 'solidus_core'
require 'solidus_support'

require 'solidus_braintree/country_mapper'
require 'solidus_braintree/request_protection'
require 'solidus_braintree/extension_configuration'
require 'solidus_braintree/version'
require 'solidus_braintree/engine'

module SolidusBraintree
  def self.table_name_prefix
    configuration.table_name_prefix
  end
end
