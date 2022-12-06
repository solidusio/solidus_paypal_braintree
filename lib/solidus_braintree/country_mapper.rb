# frozen_string_literal: true

module SolidusPaypalBraintree
  module CountryMapper
    extend ActiveSupport::Concern

    USA_VARIANTS = [
      "the united states of america",
      "united states of america",
      "the united states",
      "united states",
      "us of a",
      "u.s.a.",
      "usa",
      "u.s.",
      "us"
    ].freeze

    CANADA_VARIANTS = [
      "canada",
      "ca"
    ].freeze

    # Generates a hash mapping each variant of the country name to the same ISO
    # ie: { "usa" => "US", "united states" => "US", "canada" => "CA", ... }
    COUNTRY_MAP = {
      USA_VARIANTS => "US",
      CANADA_VARIANTS => "CA"
    }.flat_map { |variants, iso| variants.map { |v| [v, iso] } }.to_h

    included do
      def iso_from_name(country_name)
        COUNTRY_MAP[country_name.downcase.strip]
      end
    end
  end
end
