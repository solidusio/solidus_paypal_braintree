class AddPaypalButtonPreferencesToBraintreeConfigurations < ActiveRecord::Migration[5.1]
  def change
    add_column :solidus_braintree_configurations, :preferences, :text
  end
end
