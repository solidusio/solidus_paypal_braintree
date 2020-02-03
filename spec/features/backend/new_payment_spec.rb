require 'spec_helper'
require 'spree/testing_support/order_walkthrough'

shared_context "backend checkout setup" do
  let(:braintree) { new_gateway(active: true) }
  let!(:gateway) { create :payment_method }
  let!(:order) { create(:completed_order_with_totals, number: 'R9999999') }
  let(:pending_case_insensitive) { /pending/i }

  before(:each) do
    braintree.save!
    create(:store, payment_methods: [gateway, braintree]).tap do |store|
      store.braintree_configuration.update!(credit_card: true)
    end

    allow_any_instance_of(SolidusPaypalBraintree::Source).to receive(:nonce) { "fake-valid-nonce" }

    # Order and payment numbers must be identical between runs to re-use the VCR
    # cassette
    allow_any_instance_of(Spree::Payment).to receive(:number) { "123ABC" }
  end

  around(:each) do |example|
    Capybara.using_wait_time(20) { example.run }
  end
end

describe 'creating a new payment', type: :feature, js: true do
  stub_authorization!

  context "with valid credit card data", vcr: {
    cassette_name: 'admin/valid_credit_card',
    match_requests_on: [:braintree_uri]
  } do
    include_context "backend checkout setup"

    it "checks out successfully" do
      visit "/admin/orders/#{order.number}/payments/new"
      choose('Braintree')
      expect(page).to have_selector("#payment_method_#{braintree.id}", visible: true)
      expect(page).to have_selector("iframe#braintree-hosted-field-number")

      within_frame("braintree-hosted-field-number") do
        fill_in("credit-card-number", with: "4111111111111111")
      end
      within_frame("braintree-hosted-field-expirationDate") do
        fill_in("expiration", with: "02/2020")
      end
      within_frame("braintree-hosted-field-cvv") do
        fill_in("cvv", with: "123")
      end

      click_button("Update")

      within('table#payments') do
        expect(page).to have_content('Braintree')
        expect(page).to have_content(pending_case_insensitive)
      end

      click_icon(:capture)

      expect(page).not_to have_content('Cannot perform requested operation')
      expect(page).to have_content('Payment Updated')
    end
  end

  context "with invalid credit card data" do
    include_context "backend checkout setup"

    # Attempt to submit an invalid form once
    before(:each) do
      visit "/admin/orders/#{order.number}/payments/new"
      choose('Braintree')
      expect(page).to have_selector("#payment_method_#{braintree.id}", visible: true)
      expect(page).to have_selector("iframe#braintree-hosted-field-number")
      expect(page).to have_selector("iframe[type='number']")

      within_frame("braintree-hosted-field-number") do
        fill_in("credit-card-number", with: "1111111111111111")
      end
      within_frame("braintree-hosted-field-expirationDate") do
        fill_in("expiration", with: "02/2020")
      end
      within_frame("braintree-hosted-field-cvv") do
        fill_in("cvv", with: "123")
      end

      click_button "Update"
      expect(page).to have_text "BraintreeError: Some payment input fields are invalid. Cannot tokenize invalid card fields."
    end

    # Same error should be produced when submitting an empty form again
    context "user tries to resubmit another invalid form", vcr: {
      cassette_name: "admin/invalid_credit_card",
      match_requests_on: [:braintree_uri]
    } do
      it "displays a meaningful error message" do
        click_button "Update"
        expect(page).to have_text "BraintreeError: Some payment input fields are invalid. Cannot tokenize invalid card fields."
      end
    end

    # User should be able to checkout after submit fails once
    context "user enters valid data", vcr: {
      cassette_name: "admin/resubmit_credit_card",
      match_requests_on: [:braintree_uri]
    } do
      it "creates the payment successfully" do
        within_frame("braintree-hosted-field-number") do
          fill_in("credit-card-number", with: "4111111111111111")
        end
        within_frame("braintree-hosted-field-expirationDate") do
          fill_in("expiration", with: "02/2020")
        end
        within_frame("braintree-hosted-field-cvv") do
          fill_in("cvv", with: "123")
        end
        click_button("Update")

        within('table#payments') do
          expect(page).to have_content('Braintree')
          expect(page).to have_content(pending_case_insensitive)
        end

        click_icon(:capture)

        expect(page).not_to have_content('Cannot perform requested operation')
        expect(page).to have_content('Payment Updated')
      end
    end
  end
end
