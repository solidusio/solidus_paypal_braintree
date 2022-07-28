# frozen_string_literal: true

module SolidusPaypalBraintree
  class Configuration < ::Spree::Base
    PAYPAL_BUTTON_PREFERENCES = {
      color: { availables: %w[gold blue silver white black], default: 'white' },
      shape: { availables: %w[pill rect], default: 'rect' },
      label: { availables: %w[checkout credit pay buynow paypal installment], default: 'checkout' },
      tagline: { availables: %w[true false], default: 'false' },
      layout: { availables: %w[horizontal vertical], default: 'horizontal' },
      messaging: { availables: %w[true false], default: 'false' }
    }.freeze

    unless respond_to?(:preference)
      include ::Spree::Preferences::Persistable
    end

    belongs_to :store, class_name: 'Spree::Store', optional: false

    # Preferences for Paypal button
    PAYPAL_BUTTON_PREFERENCES.each do |name, desc|
      preference_name = "paypal_button_#{name}".to_sym
      attribute_name = "preferred_#{preference_name}".to_sym

      preference preference_name, :string, default: desc[:default]

      validates attribute_name, inclusion: desc[:availables]
    end

    preference :venmo_button_color, :preference_select, default: 'blue'
    preference :venmo_button_width, :preference_select, default: '320'

    def preferred_venmo_button_color_options
      [["Blue", "blue"], ["White", "white"]]
    end

    def preferred_venmo_button_width_options
      [["280", "280"], ["320", "320"], ["375", "375"]]
    end
  end
end
