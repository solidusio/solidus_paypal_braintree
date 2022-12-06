require 'spec_helper'

RSpec.describe SolidusBraintree::BraintreeCheckoutHelper do
  let!(:store) { create :store }
  let(:braintree_configuration) { {} }

  before do
    store.braintree_configuration.update(braintree_configuration)
  end

  describe '#venmo_button_style' do
    subject { helper.venmo_button_style(store) }

    context 'when the venmo button is white and has a width of 280' do
      let(:braintree_configuration) { { preferred_venmo_button_width: '280', preferred_venmo_button_color: 'white' } }

      it 'returns a hash of the width and color' do
        expect(subject).to eq({ width: '280', color: 'white' })
      end
    end

    context 'when the venmo button is blue and has a width of 375' do
      let(:braintree_configuration) { { preferred_venmo_button_width: '375', preferred_venmo_button_color: 'blue' } }

      it 'returns a hash of the width and color' do
        expect(subject).to eq({ width: '375', color: 'blue' })
      end
    end
  end

  describe '#venmo_button_width' do
    subject { helper.venmo_button_asset_url(style, active: active) }

    context 'when the given style color is white and width is 280, and the given active is false' do
      let(:style) { { width: '280', color: 'white' } }
      let(:active) { false }

      it 'returns the correct url' do
        expect(subject).to match(%r[\A/assets/solidus_paypal_braintree/venmo/venmo_white_button_280x48-.+\.svg])
      end
    end

    context 'when the given style color is white and width is 280, and the given active is true' do
      let(:style) { { width: '280', color: 'white' } }
      let(:active) { true }

      it 'returns the correct url' do
        expect(subject).to match(%r[\A/assets/solidus_paypal_braintree/venmo/venmo_active_white_button_280x48-.+\.svg])
      end
    end

    context 'when the given style color is blue and width is 320, and the given active is false' do
      let(:style) { { width: '320', color: 'blue' } }
      let(:active) { false }

      it 'returns the correct url' do
        expect(subject).to match(%r[\A/assets/solidus_paypal_braintree/venmo/venmo_blue_button_320x48-.+\.svg])
      end
    end

    context 'when the given style color is blue and width is 320, and the given active is true' do
      let(:style) { { width: '320', color: 'blue' } }
      let(:active) { true }

      it 'returns the correct url' do
        expect(subject).to match(%r[\A/assets/solidus_paypal_braintree/venmo/venmo_active_blue_button_320x48-.+\.svg])
      end
    end
  end
end
