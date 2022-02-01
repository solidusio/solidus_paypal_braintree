# frozen_string_literal: true

require 'spec_helper'
require 'spree/testing_support/order_walkthrough'

describe "Checkout", type: :feature, js: true do
  let(:braintree_preferences) { { venmo: true }.merge(preferences) }
  let(:preferences) { {} }
  let(:user) { create(:user) }
  let!(:payment_method) { create_gateway }

  before do
    create(:store, payment_methods: [payment_method]).tap do |s|
      s.braintree_configuration.update!(braintree_preferences)
    end

    go_to_payment_checkout_page
  end

  context 'with Venmo checkout' do
    context 'when Venmo is disabled' do
      let(:preferences) { { venmo: false } }

      it 'does not load the Venmo payment button' do
        expect(page).not_to have_selector('#venmo-button')
      end
    end

    context 'when Venmo is enabled' do
      it 'loads the Venmo payment button' do
        expect(page).to have_selector('#venmo-button')
      end
    end

    context "when Venmo's button style is customized" do
      context 'when venmo_button_color is "blue" and venmo_button_width is "280"' do
        let(:preferences) { { preferred_venmo_button_color: 'blue', preferred_venmo_button_width: '280' } }

        it 'has the correct style' do
          venmo_button.assert_matches_style(width: '280px', 'background-image': /venmo_blue_button_280x48/)
          venmo_button.hover
          venmo_button.assert_matches_style('background-image': /venmo_active_blue_button_280x48/)
        end
      end

      context 'when venmo_button_color is "white" and venmo_button_width is "375"' do
        let(:preferences) { { preferred_venmo_button_color: 'white', preferred_venmo_button_width: '375' } }

        it 'has the correct style' do
          venmo_button.assert_matches_style(width: '375px', 'background-image': /venmo_white_button_375x48/)
          venmo_button.hover
          venmo_button.assert_matches_style('background-image': /venmo_active_white_button_375x48/)
        end
      end
    end

    context 'when the Venmo button is clicked' do
      before { venmo_button.click }

      it 'opens the QR modal which shows an error when closed' do
        within_frame(venmo_frame) do
          expect(page).to have_selector('#venmo-qr-code-view')

          click_button('close-icon')

          expect(page).not_to have_selector('#venmo-qr-code-view')
        end

        expect(page).to have_content('Venmo authorization was canceled by closing the Venmo Desktop modal.')
      end
    end

    context 'with Venmo transactions', vcr: { cassette_name: 'checkout/valid_venmo_transaction' } do
      before do
        fake_venmo_successful_tokenization
      end

      context 'with CreditCard disabled' do
        it 'can checkout with Venmo' do
          next_checkout_step
          finalize_checkout

          expect(Spree::Order.last.complete?).to eq(true)
        end
      end

      # To test that the hosted-fields inputs do not conflict with Venmo's
      context 'with CreditCard enabled' do
        let(:preferences) { { credit_card: true } }

        it 'can checkout with Venmo' do
          disable_hosted_fields_inputs
          disable_hosted_fields_form_listener

          next_checkout_step
          finalize_checkout

          expect(Spree::Order.last.complete?).to eq(true)
          expect(Spree::Payment.last.source.venmo?).to eq(true)
        end
      end

      # https://developer.paypal.com/braintree/docs/guides/venmo/client-side#custom-integration
      it "meet's Braintree's acceptance criteria during checkout", aggregate_failures: true do
        next_checkout_step

        expect(page).to have_content('Payment Type: Venmo')

        finalize_checkout

        expect(page).to have_content('Venmo Account: venmojoe')
      end

      # the VCR must be based on this test, so it includes HTTP requests of the second order
      it 'saves the used Venmo source in the wallet and can be reused' do
        next_checkout_step
        finalize_checkout
        go_to_payment_checkout_page(order_number: 'R300000002')

        expect(Spree::User.first.wallet.wallet_payment_sources).not_to be_empty
        expect(page).to have_selector('#existing_cards')
        expect(page).to have_content('venmojoe')

        next_checkout_step
        finalize_checkout

        expect(Spree::Order.all.all?(&:complete?)).to eq(true)
      end
    end
  end

  private

  def go_to_payment_checkout_page(order_number: 'R300000001' )
    order = if Spree.solidus_gem_version >= Gem::Version.new('2.6.0')
              Spree::TestingSupport::OrderWalkthrough.up_to(:address)
            else
              OrderWalkthrough.up_to(:address)
            end

    order.update!(user: user, number: order_number) # constant order number for VCRs

    allow_any_instance_of(Spree::CheckoutController).to receive_messages(current_order: order)
    allow_any_instance_of(Spree::CheckoutController).to receive_messages(try_spree_current_user: Spree::User.first)
    allow_any_instance_of(Spree::Payment).to receive(:gateway_order_id).and_return(order_number)

    visit spree.checkout_state_path(order.state)
    next_checkout_step
  end

  def next_checkout_step
    click_button('Save and Continue')
  end

  def finalize_checkout
    click_button('Place Order')
  end

  def venmo_button
    find_button('venmo-button', disabled: false)
  end

  def venmo_frame
    find('#venmo-desktop-iframe')
  end

  def fake_venmo_successful_tokenization
    enable_venmo_inputs
    fake_payment_method_nonce
  end

  def enable_venmo_inputs
    page.execute_script("$('.venmo-fields input').each(function(_index, input){input.removeAttribute('disabled');});")
  end

  def fake_payment_method_nonce
    page.execute_script("$('#venmo_payment_method_nonce').val('fake-venmo-account-nonce');")
  end

  def disable_hosted_fields_inputs
    page.execute_script("$('.hosted-fields input').each(function(_index, input){input.disabled=true;});")
  end

  def disable_hosted_fields_form_listener
    # Once the submit button is enabled, the submit listener has been added
    find("#checkout_form_payment input[type='submit']:not(:disabled)")
    page.execute_script("$('#checkout_form_payment').off('submit');")
  end
end
