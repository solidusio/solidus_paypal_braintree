require 'spec_helper'

describe "Checkout", type: :feature, js: true do
  Capybara.default_max_wait_time = 60
  let!(:store) do
    create(:store, payment_methods: [payment_method]).tap do |s|
      s.braintree_configuration.update!(paypal: true)
    end
  end
  let!(:country) { create(:country, states_required: true) }
  let!(:state) { create(:state, country: country, abbr: "CA", name: "California") }
  let!(:shipping_method) { create(:shipping_method) }
  let!(:stock_location) { create(:stock_location) }
  let!(:mug) { create(:product, name: "RoR Mug") }
  let!(:payment_method) { create_gateway }
  let!(:zone) { create(:zone) }

  context "goes through checkout using paypal one touch", vcr: { cassette_name: 'paypal/one_touch_checkout', match_requests_on: [:method, :uri] } do
    before do
      payment_method
      add_mug_to_cart
    end

    it "should check out successfully using one touch" do
      pend_if_paypal_slow do
        move_through_paypal_popup
        expect(page).to have_content("Shipments")
        click_on "Place Order"
        expect(page).to have_content("Your order has been processed successfully")
      end
    end
  end

  context "goes through checkout using paypal", vcr: { cassette_name: 'paypal/checkout', match_requests_on: [:method, :uri] } do
    before do
      payment_method
      add_mug_to_cart
    end

    it "should check out successfully through regular checkout" do
      expect(page).to have_button("paypal-button")
      click_button("Checkout")
      fill_in("order_email", with: "stembolt_buyer@stembolttest.com")
      click_button("Continue")
      expect(page).to have_content("Customer E-Mail")
      fill_in_address
      click_button("Save and Continue")
      expect(page).to have_content("SHIPPING METHOD")
      click_button("Save and Continue")
      pend_if_paypal_slow do
        move_through_paypal_popup
        expect(page).to have_content("Shipments")
        click_on "Place Order"
        expect(page).to have_content("Your order has been processed successfully")
      end
    end
  end

  # Selenium does not clear cookies properly between test runs, even when
  # using Capybara.reset_sessions!, see:
  # https://github.com/jnicklas/capybara/issues/535
  #
  # This causes Paypal to remain logged in and not prompt for an email on the
  # second test run and causes the test to fail. Adding conditional logic for
  # this greatly increases the test time, so it is left out since CI runs
  # these with poltergeist.
  def move_through_paypal_popup
    expect(page).to have_button("paypal-button")
    popup = page.window_opened_by do
      click_button("paypal-button")
    end
    page.switch_to_window(popup)

    # We don't control this popup window.
    # So javascript errors are not our errors.
    begin
      expect(page).to_not have_selector('body.loading')
      page.within_frame("injectedUl") do
        fill_in("email", with: "stembolt_buyer@stembolttest.com")
        fill_in("password", with: "test1234")
      end

      # The check for 'body.loading' check doesn't work well from the within_frame
      # context, so we need to jump out before performing that check.
      expect(page).to_not have_selector('body.loading')
      page.within_frame("injectedUl") do
        click_button("btnLogin")
      end

      expect(page).to_not have_selector('body.loading')
      click_button("Agree & Continue")
    rescue Capybara::Poltergeist::JavascriptError => e
      pending "PayPal had javascript errors in their popup window."
      raise e
    rescue Capybara::ElementNotFound => e
      pending "PayPal delivered unkown HTML in their popup window."
      raise e
    rescue Capybara::Poltergeist::NoSuchWindowError => e
      pending "PayPal popup not available."
      raise e
    end

    page.switch_to_window(page.windows.first)
  end

  def fill_in_address
    address = "order_bill_address_attributes"
    fill_in "#{address}_firstname", with: "Ryan"
    fill_in "#{address}_lastname", with: "Bigg"
    fill_in "#{address}_address1", with: "143 Swan Street"
    fill_in "#{address}_city", with: "San Jose"
    select "United States of America", from: "#{address}_country_id"
    select "California", from: "#{address}_state_id"
    fill_in "#{address}_zipcode", with: "95131"
    fill_in "#{address}_phone", with: "(555) 555-0111"
  end

  def add_mug_to_cart
    visit spree.root_path
    click_link mug.name
    click_button "add-to-cart-button"
  end

  def pend_if_paypal_slow
    yield
  rescue RSpec::Expectations::ExpectationNotMetError => e
    pending "PayPal did not answer in #{Capybara.default_max_wait_time} seconds."
    raise e
  rescue Capybara::Poltergeist::JavascriptError => e
    pending "PayPal delivered wrong payload because of errors in their popup window."
    raise e
  end
end
