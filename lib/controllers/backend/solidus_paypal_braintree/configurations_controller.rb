module SolidusPaypalBraintree
  class ConfigurationsController < Spree::Admin::BaseController
    helper RoutesHelper

    def list
      authorize! :list, SolidusPaypalBraintree::Configuration

      @configurations = Spree::Store.all.map(&:braintree_configuration)
    end

    def update
      authorize! :update, SolidusPaypalBraintree::Configuration

      params = configurations_params[:configuration_fields]
      if SolidusPaypalBraintree::Configuration.update(params.keys, params.values)
        flash[:success] = t('update_success', scope: 'solidus_paypal_braintree.configurations')
      else
        flash[:error] = t('update_error', scope: 'solidus_paypal_braintree.configurations')
      end
      redirect_to action: :list
    end

    private

    def configurations_params
      params.require(:configurations).
        permit(configuration_fields: [:paypal, :apple_pay, :credit_card])
    end
  end
end
