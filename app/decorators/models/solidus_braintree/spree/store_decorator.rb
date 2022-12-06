# frozen_string_literal: true

module SolidusPaypalBraintree
  module Spree
    module StoreDecorator
      def self.prepended(base)
        base.has_one :braintree_configuration, class_name: "SolidusPaypalBraintree::Configuration", dependent: :destroy
        base.before_create :build_default_configuration
      end

      private

      def build_default_configuration
        build_braintree_configuration unless braintree_configuration
      end

      ::Spree::Store.prepend self
    end
  end
end
