require 'spec_helper'

describe "Checkout", type: :feature, js: true do
  Capybara.default_max_wait_time = 30
  let!(:store) { create(:store, payment_methods: [payment_method]) }
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
      move_through_paypal_popup
      expect(page).to have_content("Shipments")
      click_on "Place Order"
      expect(page).to have_content("Your order has been processed successfully")
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
      move_through_paypal_popup
      expect(page).to have_content("Shipments")
      click_on "Place Order"
      expect(page).to have_content("Your order has been processed successfully")
    end
  end

  def move_through_paypal_popup
      expect(page).to have_button("paypal-button")
      popup = page.window_opened_by do
        click_button("paypal-button")
      end
      page.switch_to_window(popup)
      expect(page).to_not have_selector('body', class: 'loading')
      # Necessary on drivers that save the login from the previous test
      if page.has_content?("Not you?")
        click_link("Not you?")
      end
      expect(page).to_not have_selector('body', class: 'loading')
      page.within_frame("injectedUl") do
        fill_in("email", with: "stembolt_buyer@stembolttest.com")
        fill_in("password", with: "test1234")
        click_button("btnLogin")
      end
      expect(page).to_not have_selector('body', class: 'loading')
      # Sometimes the first click doesn't work
      if !page.has_button?("Agree & Continue")
        page.within_frame("injectedUl") do
          puts "login failed, retrying"
          click_button("btnLogin")
        end
      end
      click_button("Agree & Continue")
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
end
