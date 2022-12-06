class AddVenmoToBraintreeConfiguration < ActiveRecord::Migration[5.0]
  def change
    add_column :solidus_braintree_configurations, :venmo, :boolean, null: false, default: false
  end
end
