require 'spec_helper'

RSpec.describe SolidusPaypalBraintree::AVSResult do
  describe 'AVS response message' do
    subject { described_class.build(transaction).to_hash['message'] }

    context 'with avs_error_response_code' do
      let(:transaction) do
        instance_double('Braintree::Transaction',
          avs_error_response_code: error_code,
          avs_street_address_response_code: nil,
          avs_postal_code_response_code: nil)
      end

      context 'when error code is S' do
        let(:error_code) { 'S' }

        it { is_expected.to eq 'U.S.-issuing bank does not support AVS.' }
      end

      context 'when error code is E' do
        let(:error_code) { 'E' }

        it { is_expected.to eq 'AVS data is invalid or AVS is not allowed for this card type.' }
      end
    end

    context 'without avs_error_response_code' do
      let(:transaction) do
        instance_double('Braintree::Transaction',
          avs_error_response_code: nil,
          avs_street_address_response_code: codes.first,
          avs_postal_code_response_code: codes.last)
      end

      context 'when street address result is M and postal code result is N' do
        let(:codes) { %w(M N) }

        it { is_expected.to eq 'Street address matches, but postal code does not match.' }

        it {
          expect(described_class.build(transaction).to_hash).to include('street_match' => 'M', 'postal_match' => 'N')
        }
      end

      context 'when street address result is M and postal code result is U' do
        let(:codes) { %w(M U) }

        it { is_expected.to eq 'Street address matches, but postal code not verified.' }

        it {
          expect(described_class.build(transaction).to_hash).to include('street_match' => 'M', 'postal_match' => 'U')
        }
      end

      context 'when street address result is M and postal code result is I' do
        let(:codes) { %w(M I) }

        it { is_expected.to eq 'Street address matches, but postal code not verified.' }

        it {
          expect(described_class.build(transaction).to_hash).to include('street_match' => 'M', 'postal_match' => 'I')
        }
      end

      context 'when street address result is M and postal code result is A' do
        let(:codes) { %w(M A) }

        it { is_expected.to eq 'Street address matches, but postal code not verified.' }

        it {
          expect(described_class.build(transaction).to_hash).to include('street_match' => 'M', 'postal_match' => 'A')
        }
      end

      context 'when street address result is N and postal code result is N' do
        let(:codes) { %w(N N) }

        it { is_expected.to eq 'Street address and postal code do not match.' }

        it {
          expect(described_class.build(transaction).to_hash).to include('street_match' => 'N', 'postal_match' => 'N')
        }
      end

      context 'when street address result is N and postal code result is U' do
        let(:codes) { %w(N U) }

        it { is_expected.to eq 'Street address and postal code do not match.' }

        it {
          expect(described_class.build(transaction).to_hash).to include('street_match' => 'N', 'postal_match' => 'U')
        }
      end

      context 'when street address result is N and postal code result is I' do
        let(:codes) { %w(N I) }

        it { is_expected.to eq 'Street address and postal code do not match.' }

        it {
          expect(described_class.build(transaction).to_hash).to include('street_match' => 'N', 'postal_match' => 'I')
        }
      end

      context 'when street address result is N and postal code result is A' do
        let(:codes) { %w(N A) }

        it { is_expected.to eq 'Street address and postal code do not match.' }

        it {
          expect(described_class.build(transaction).to_hash).to include('street_match' => 'N', 'postal_match' => 'A')
        }
      end

      context 'when street address result is I and postal code result is N' do
        let(:codes) { %w(I N) }

        it { is_expected.to eq 'Street address and postal code do not match.' }

        it {
          expect(described_class.build(transaction).to_hash).to include('street_match' => 'I', 'postal_match' => 'N')
        }
      end

      context 'when street address result is A and postal code result is N' do
        let(:codes) { %w(A N) }

        it { is_expected.to eq 'Street address and postal code do not match.' }

        it {
          expect(described_class.build(transaction).to_hash).to include('street_match' => 'A', 'postal_match' => 'N')
        }
      end

      context 'when street address result is U and postal code result is U' do
        let(:codes) { %w(U U) }

        it { is_expected.to eq 'Address not verified.' }

        it {
          expect(described_class.build(transaction).to_hash).to include('street_match' => 'U', 'postal_match' => 'U')
        }
      end

      context 'when street address result is U and postal code result is I' do
        let(:codes) { %w(U I) }

        it { is_expected.to eq 'Address not verified.' }

        it {
          expect(described_class.build(transaction).to_hash).to include('street_match' => 'U', 'postal_match' => 'I')
        }
      end

      context 'when street address result is U and postal code result is A' do
        let(:codes) { %w(U A) }

        it { is_expected.to eq 'Address not verified.' }

        it {
          expect(described_class.build(transaction).to_hash).to include('street_match' => 'U', 'postal_match' => 'A')
        }
      end

      context 'when street address result is I and postal code result is U' do
        let(:codes) { %w(I U) }

        it { is_expected.to eq 'Address not verified.' }

        it {
          expect(described_class.build(transaction).to_hash).to include('street_match' => 'I', 'postal_match' => 'U')
        }
      end

      context 'when street address result is I and postal code result is I' do
        let(:codes) { %w(I I) }

        it { is_expected.to eq 'Address not verified.' }

        it {
          expect(described_class.build(transaction).to_hash).to include('street_match' => 'I', 'postal_match' => 'I')
        }
      end

      context 'when street address result is I and postal code result is A' do
        let(:codes) { %w(I A) }

        it { is_expected.to eq 'Address not verified.' }

        it {
          expect(described_class.build(transaction).to_hash).to include('street_match' => 'I', 'postal_match' => 'A')
        }
      end

      context 'when street address result is A and postal code result is U' do
        let(:codes) { %w(A U) }

        it { is_expected.to eq 'Address not verified.' }

        it {
          expect(described_class.build(transaction).to_hash).to include('street_match' => 'A', 'postal_match' => 'U')
        }
      end

      context 'when street address result is A and postal code result is I' do
        let(:codes) { %w(A I) }

        it { is_expected.to eq 'Address not verified.' }

        it {
          expect(described_class.build(transaction).to_hash).to include('street_match' => 'A', 'postal_match' => 'I')
        }
      end

      context 'when street address result is A and postal code result is A' do
        let(:codes) { %w(A A) }

        it { is_expected.to eq 'Address not verified.' }

        it {
          expect(described_class.build(transaction).to_hash).to include('street_match' => 'A', 'postal_match' => 'A')
        }
      end

      context 'when street address result is M and postal code result is M' do
        let(:codes) { %w(M M) }

        it { is_expected.to eq 'Street address and postal code match.' }

        it {
          expect(described_class.build(transaction).to_hash).to include('street_match' => 'M', 'postal_match' => 'M')
        }
      end

      context 'when street address result is U and postal code result is N' do
        let(:codes) { %w(U N) }

        it { is_expected.to eq "Street address and postal code do not match. For American Express: Card member's name, street address and postal code do not match." } # rubocop:disable Layout/LineLength

        it {
          expect(described_class.build(transaction).to_hash).to include('street_match' => 'U', 'postal_match' => 'N')
        }
      end

      context 'when street address result is U and postal code result is M' do
        let(:codes) { %w(U M) }

        it { is_expected.to eq 'Postal code matches, but street address not verified.' }

        it {
          expect(described_class.build(transaction).to_hash).to include('street_match' => 'U', 'postal_match' => 'M')
        }
      end

      context 'when street address result is I and postal code result is M' do
        let(:codes) { %w(I M) }

        it { is_expected.to eq 'Postal code matches, but street address not verified.' }

        it {
          expect(described_class.build(transaction).to_hash).to include('street_match' => 'I', 'postal_match' => 'M')
        }
      end

      context 'when street address result is A and postal code result is M' do
        let(:codes) { %w(A M) }

        it { is_expected.to eq 'Postal code matches, but street address not verified.' }

        it {
          expect(described_class.build(transaction).to_hash).to include('street_match' => 'A', 'postal_match' => 'M')
        }
      end

      context 'when street address result is N and postal code result is M' do
        let(:codes) { %w(N M) }

        it { is_expected.to eq 'Street address does not match, but 5-digit postal code matches.' }

        it {
          expect(described_class.build(transaction).to_hash).to include('street_match' => 'N', 'postal_match' => 'M')
        }
      end

      context 'when street address response code is nil' do
        let(:codes) { [nil, 'M'] }

        it { is_expected.to be_nil }

        it {
          expect(described_class.build(transaction).to_hash).to include('street_match' => nil, 'postal_match' => 'M')
        }
      end

      context 'when postal code response code is nil' do
        let(:codes) { ['M', nil] }

        it { is_expected.to be_nil }

        it {
          expect(described_class.build(transaction).to_hash).to include('street_match' => 'M', 'postal_match' => nil)
        }
      end

      context 'when postal code and street address response code is nil' do
        let(:codes) { [nil, nil] }

        it { is_expected.to be_nil }

        it {
          expect(described_class.build(transaction).to_hash).to include('street_match' => nil, 'postal_match' => nil)
        }
      end
    end
  end
end
