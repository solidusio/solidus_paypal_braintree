require 'spec_helper'

RSpec.describe "viewing the configuration interface" do
  stub_authorization!

  # Regression to ensure this page still renders on old versions of solidus
  scenario "should not raise any errors due to unavailable route helpers" do
    visit "/solidus_paypal_braintree/configurations/list"
    expect(page).to have_content("Braintree Configurations")
  end

  # Regression to ensure this page renders on Solidus 2.4
  scenario 'should not raise any errors due to unavailable preference field partial' do
    Rails.application.config.spree.payment_methods << SolidusPaypalBraintree::Gateway
    Spree::PaymentMethod.create!(
      type: 'SolidusPaypalBraintree::Gateway',
      name: 'Braintree Payments'
    )
    visit '/admin/payment_methods'
    page.find('a[title="Edit"]').click
    expect(page).to have_field 'Name', with: 'Braintree Payments'
  end
end
