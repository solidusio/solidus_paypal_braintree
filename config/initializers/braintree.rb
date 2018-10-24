Spree::Admin::PaymentsController.helper :braintree_admin

if Spree::Backend::Config.respond_to?(:menu_items)
  Spree::Backend::Config.configure do |config|
    config.menu_items << config.class::MenuItem.new(
      [:paypal_braintree],
      'wrench',
      label: 'Braintree',
      url: "#{ActionController::Base.relative_url_root}/solidus_paypal_braintree/configurations/list"
    )
  end
end
