class AddPaypalFundingSourceToSolidusBraintreeSources < ActiveRecord::Migration[5.0]
  def change
    add_column :solidus_braintree_sources, :paypal_funding_source, :integer
  end
end
