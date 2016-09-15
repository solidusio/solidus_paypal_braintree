require 'spec_helper'

describe SolidusPaypalBraintree::TransactionAddress do
  describe "#valid?" do
    subject { described_class.new(valid_attributes).valid? }

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

    it { is_expected.to be true }

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
    end

    context "no country_code" do
      let(:valid_attributes) { super().except(:country_code) }
      it { is_expected.to be false }
    end
  end
end
