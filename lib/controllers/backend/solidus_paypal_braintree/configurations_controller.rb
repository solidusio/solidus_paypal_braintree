# frozen_string_literal: true

module SolidusPaypalBraintree
  class ConfigurationsController < ::Spree::Admin::BaseController
    helper ::Spree::Core::Engine.routes.url_helpers

    def list
      authorize! :list, SolidusPaypalBraintree::Configuration

      @configurations = ::Spree::Store.all.map { |s| s.braintree_configuration || s.create_braintree_configuration }
    end

    def update
      authorize! :update, SolidusPaypalBraintree::Configuration

      params = configurations_params[:configuration_fields]
      results = SolidusPaypalBraintree::Configuration.update(params.keys, params.values)
      if results.all?(&:valid?)
        flash[:success] = t('update_success', scope: 'solidus_paypal_braintree.configurations')
      else
        flash[:error] = t('update_error', scope: 'solidus_paypal_braintree.configurations')
      end
      redirect_to action: :list
    end

    private

    def configurations_params
      params.require(:configurations).
        permit(configuration_fields: [
          :paypal,
          :apple_pay,
          :venmo,
          :credit_card,
          :three_d_secure,
          :preferred_paypal_button_locale,
          :preferred_paypal_button_color,
          :preferred_paypal_button_shape,
          :preferred_paypal_button_label,
          :preferred_paypal_button_tagline,
          :preferred_paypal_button_layout,
          :preferred_paypal_button_messaging,
          :preferred_venmo_button_color,
          :preferred_venmo_button_width
        ])
    end
  end
end
