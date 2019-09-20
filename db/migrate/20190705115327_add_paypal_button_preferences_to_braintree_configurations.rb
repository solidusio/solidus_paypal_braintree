class AddPaypalButtonPreferencesToBraintreeConfigurations < ActiveRecord::Migration[5.1]
  def change
    add_column :solidus_paypal_braintree_configurations, :preferences, :text
  end
end
