module SolidusPaypalBraintree
  module RoutesHelper
    def method_missing(method_sym, *arguments, &block)
      if spree.respond_to?(method_sym)
        spree.send(method_sym, arguments)
      else
        super
      end
    end

    def respond_to_missing?(method_sym, include_private = false)
      spree.respond_to?(method_sym) || super
    end
  end
end
