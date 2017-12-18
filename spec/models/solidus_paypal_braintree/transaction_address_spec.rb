require 'spec_helper'

describe SolidusPaypalBraintree::TransactionAddress do
  describe "#valid?" do
    let(:address) { described_class.new(valid_attributes) }

    subject { address.valid? }

    let(:valid_attributes) do
      {
        first_name: "Bruce",
        last_name: "Wayne",
        address_line_1: "42 Spruce Lane",
        city: "Gotham",
        zip: "98201",
        state_code: "WA",
        country_code: "US"
      }
    end

    let!(:country) { create :country, iso: 'US', states_required: true }
    let!(:state) { create :state, abbr: 'WA', country: country }

    it { is_expected.to be true }

    context 'no country matches' do
      let(:valid_attributes) { super().merge({ country_code: 'CA' }) }

      it { is_expected.to be false }
    end

    context "no first_name" do
      let(:valid_attributes) { super().except(:first_name) }
      it { is_expected.to be false }
    end

    context "no last_name" do
      let(:valid_attributes) { super().except(:last_name) }
      it { is_expected.to be false }
    end

    context "no address_line_1" do
      let(:valid_attributes) { super().except(:address_line_1) }
      it { is_expected.to be false }
    end

    context "no city" do
      let(:valid_attributes) { super().except(:city) }
      it { is_expected.to be false }
    end

    context "no zip" do
      let(:valid_attributes) { super().except(:zip) }
      it { is_expected.to be false }
    end

    context "no state_code" do
      let(:valid_attributes) { super().except(:state_code) }
      it { is_expected.to be false }

      context "when country does not requires states" do
        let!(:country) { create :country, iso: 'US', states_required: false }

        it { is_expected.to be true }
      end
    end

    context "no country_code" do
      let(:valid_attributes) { super().except(:country_code) }

      it { is_expected.to be true }

      it "defaults to the US" do
        subject
        expect(address.country_code).to eq "us"
      end
    end
  end

  describe "#attributes=" do
    subject { described_class.new(attrs) }

    context "when an ISO code is provided" do
      let(:attrs) { { country_code: "US" } }

      it "uses the ISO code provided" do
        expect(subject.country_code).to eq "US"
      end
    end

    context "when the ISO code is blank" do
      context "and a valid country name is provided" do
        let!(:canada) { create :country, name: "Canada", iso: "CA" }
        let(:attrs) { { country_name: "Canada" } }

        it "looks up the ISO code by the country name" do
          expect(subject.country_code).to eq "CA"
        end
      end

      context "and no valid country name is provided" do
        let(:attrs) { { country_name: "Neverland" } }

        it "leaves the country code blank" do
          expect(subject.country_code).to be_nil
        end
      end
    end
  end

  describe '#spree_country' do
    subject { described_class.new(country_code: country_code).spree_country }

    before do
      create :country, name: 'United States', iso: 'US'
    end

    ['us', 'US'].each do |code|
      let(:country_code) { code }

      it 'looks up by iso' do
        expect(subject.name).to eq 'United States'
      end
    end

    context 'country does not exist' do
      let(:country_code) { 'NA' }

      it { is_expected.to be_nil }
    end
  end

  describe '#spree_state' do
    subject { described_class.new(country_code: 'US', state_code: state_code).spree_state }
    let(:state_code) { 'newy' }

    it { is_expected.to be_nil }

    context 'state exists' do
      before do
        us = create :country, iso: 'US'
        create :state, abbr: 'NY', name: 'New York', country: us
      end

      ['ny', ' ny', 'ny ', 'New York', 'new york', 'NY'].each do |code|
        let(:state_code) { code }

        it 'looks up the right state' do
          expect(subject.abbr).to eq "NY"
        end
      end

      context 'returns nil if no state matches' do
        let(:state_code) { 'AL' }
        it { is_expected.to be_nil }
      end
    end
  end

  describe '#should_match_state_model' do
    subject { described_class.new(country_code: 'US').should_match_state_model? }

    it { is_expected.to be_falsey }

    context 'country does not require states' do
      before { create :country, iso: 'US', states_required: false }

      it { is_expected.to be false }
    end

    context 'country requires states' do
      before { create :country, iso: 'US', states_required: true }

      it { is_expected.to be true }
    end
  end

  describe '#to_spree_address' do
    subject { described_class.new(country_code: 'US', state_code: 'NY').to_spree_address }

    let!(:us) { create :country, iso: 'US' }

    it { is_expected.to be_a Spree::Address }

    context 'country exists with states' do
      before do
        create :state, country: us, abbr: 'NY', name: 'New York'
      end
      it 'uses state model' do
        expect(subject.state.name).to eq 'New York'
      end
    end

    context 'country exist with no states' do
      it 'uses state_name' do
        expect(subject.state).to be_nil
        expect(subject.state_text).to eq 'NY'
      end
    end
  end
end
