require 'spec_helper'

RSpec.describe SolidusPaypalBraintree::Address do
  describe '#to_json' do
    subject(:address_json) { JSON.parse(described_class.new(spree_address).to_json) }

    let(:german_address) { create(:address, country_iso: 'DE', state: nil) } # Does not require states
    let(:us_address) { create(:address, country_iso: 'US') } # Requires states
    let(:spree_address) { us_address }

    before do
      create(:country, iso: 'DE', states_required: false)
      create(:country, iso: 'US', states_required: true)
    end

    it 'has all the required keys' do
      expect(address_json.keys).to contain_exactly(
        'line1',
        'line2',
        'city',
        'postalCode',
        'countryCode',
        'recipientName',
        'state',
        'phone'
      )
    end

    context 'with a country that does not require state' do
      let(:spree_address) { german_address }

      it { is_expected.not_to have_key('state') }
    end

    context 'with states turned off globally' do
      before do
        allow(::Spree::Config).to receive(:address_requires_state).and_return(false)
      end

      context 'with a country that requires states' do
        it { is_expected.not_to have_key('state') }
      end

      context 'with a country that does not require state' do
        let(:spree_address) { german_address }

        it { is_expected.not_to have_key('state') }
      end
    end
  end
end
