require 'spec_helper'
require 'spree/testing_support/order_walkthrough'

shared_context "frontend checkout setup" do
  let(:braintree) { new_gateway(active: true) }
  let!(:gateway) { create :payment_method }
  let(:three_d_secure_enabled) { false }
  let(:card_number) { "4111111111111111" }
  let(:card_expiration) { "01/#{Time.now.year+2}" }
  let(:card_cvv) { "123" }

  before(:each) do
    braintree.save!

    create(:store, payment_methods: [gateway, braintree]).tap do |store|
      store.braintree_configuration.update!(
        credit_card: true,
        three_d_secure: three_d_secure_enabled
      )
    end

    if SolidusSupport.solidus_gem_version >= Gem::Version.new('2.6.0')
      order = Spree::TestingSupport::OrderWalkthrough.up_to(:delivery)
    else
      order = OrderWalkthrough.up_to(:delivery)
    end

    user = create(:user)
    order.user = user
    order.number = "R9999999"
    order.recalculate

    allow_any_instance_of(Spree::CheckoutController).to receive_messages(current_order: order)
    allow_any_instance_of(Spree::CheckoutController).to receive_messages(try_spree_current_user: user)
    allow_any_instance_of(Spree::Payment).to receive(:number) { "123ABC" }
    allow_any_instance_of(SolidusPaypalBraintree::Source).to receive(:nonce) { "fake-valid-nonce" }

    visit spree.checkout_state_path(:delivery)
    click_button "Save and Continue"
    choose("Braintree")
    expect(page).to have_selector("#payment_method_#{braintree.id}", visible: true)
    expect(page).to have_selector("iframe#braintree-hosted-field-number")
  end

  around(:each) do |example|
    Capybara.using_wait_time(20) { example.run }
  end
end

describe 'entering credit card details', type: :feature, js: true do
  context "with valid credit card data", vcr: {
    cassette_name: 'checkout/valid_credit_card',
    match_requests_on: [:braintree_uri]
  } do
    include_context "frontend checkout setup"

    before do
      within_frame("braintree-hosted-field-number") do
        fill_in("credit-card-number", with: card_number)
      end
      within_frame("braintree-hosted-field-expirationDate") do
        fill_in("expiration", with: card_expiration)
      end
      within_frame("braintree-hosted-field-cvv") do
        fill_in("cvv", with: card_cvv)
      end

      click_button("Save and Continue")
    end

    it "checks out successfully" do
      within("#order_details") do
        expect(page).to have_content("CONFIRM")
      end
      click_button("Place Order")
      expect(page).to have_content("Your order has been processed successfully")
    end

    context 'and having 3D secure enabled' do
      let(:three_d_secure_enabled) { true }
      let(:card_number) { "4000000000000002" }
      let(:card_cvv) { "123" }

      it 'checks out successfully' do
        authenticate_3ds

        within("#order_details") do
          expect(page).to have_content("CONFIRM")
        end

        click_button("Place Order")
        expect(page).to have_content("Your order has been processed successfully")
      end

      context 'with 3ds authentication error' do
        let(:card_number) { "4000000000000028" }
        let(:card_cvv) { "123" }

        it 'shows a 3ds authentication error' do
          authenticate_3ds
          expect(page).to have_content("3D Secure authentication failed. Please try again using a different payment method.")
        end
      end

    end
  end

  context "with invalid credit card data" do
    include_context "frontend checkout setup"

    # Attempt to submit an empty form once
    before(:each) do
      expect(page).to have_selector("iframe[type='number']")
      click_button "Save and Continue"
      expect(page).to have_text I18n.t("solidus_paypal_braintree.errors.empty_fields")
      expect(page).to have_selector("input[type='submit']:enabled")
    end

    # Same error should be produced when submitting an empty form again
    context "user tries to resubmit an empty form", vcr: { cassette_name: "checkout/invalid_credit_card" } do
      it "displays an alert with a meaningful error message" do
        expect(page).to have_selector("input[type='submit']:enabled")

        click_button "Save and Continue"
        expect(page).to have_text I18n.t("solidus_paypal_braintree.errors.empty_fields")
      end
    end

    # User should be able to checkout after submit fails once
    context "user enters valid data", vcr: {
      cassette_name: "checkout/resubmit_credit_card",
      match_requests_on: [:braintree_uri]
    } do

      it "allows them to resubmit and complete the purchase" do
        within_frame("braintree-hosted-field-number") do
          fill_in("credit-card-number", with: "4111111111111111")
        end
        within_frame("braintree-hosted-field-expirationDate") do
          fill_in("expiration", with: card_expiration)
        end
        within_frame("braintree-hosted-field-cvv") do
          fill_in("cvv", with: "123")
        end
        click_button("Save and Continue")
        within("#order_details") do
          expect(page).to have_content("CONFIRM")
        end
        click_button("Place Order")
        expect(page).to have_content("Your order has been processed successfully")
      end
    end
  end

  def authenticate_3ds
    within_frame("Cardinal-CCA-IFrame") do
      within_frame("authWindow") do
        fill_in("password", with: "1234")
        click_button("Submit")
      end
    end
  end
end
