require 'spec_helper'
require 'spree/testing_support/order_walkthrough'

shared_context "checkout setup" do
  let(:braintree) { new_gateway(active: true) }
  let!(:gateway) { create :payment_method }
  let!(:order) { create(:completed_order_with_totals, number: 'R9999999') }

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

  context "with valid credit card data", vcr: { cassette_name: 'admin/valid_credit_card' } do
    include_context "checkout setup"

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

      within('table#payments .payment') do
        expect(page).to have_content('Braintree')
        expect(page).to have_content('pending')
      end

      click_icon(:capture)

      expect(page).not_to have_content('Cannot perform requested operation')
      expect(page).to have_content('Payment Updated')
    end
  end
end
