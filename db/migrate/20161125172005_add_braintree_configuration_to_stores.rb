class AddBraintreeConfigurationToStores < SolidusSupport::Migration[4.2]
  def up
    Spree::Store.all.each(&:create_braintree_configuration)
  end

  def down
    SolidusPaypalBraintree::Configuration.joins(:store).destroy_all
  end
end
