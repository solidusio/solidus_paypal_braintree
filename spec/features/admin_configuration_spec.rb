require 'spec_helper'

RSpec.describe "viewing the configuration interface", js: true do
  stub_authorization!

  # Regression to ensure this page still renders on old versions of solidus
  scenario "should not raise any errors due to unavailable route helpers" do
    visit "/solidus_paypal_braintree/configurations/list"
    expect(page).to have_content("Braintree Configurations")
  end
end
