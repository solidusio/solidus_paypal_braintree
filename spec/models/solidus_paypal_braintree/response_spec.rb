require 'spec_helper'

RSpec.describe SolidusPaypalBraintree::Response do
  let(:failed_transaction) { nil }
  let(:error) do
    instance_double(
      'Braintree::ValidationError',
      code: '12345',
      message: "Cannot refund a transaction unless it is settled."
    )
  end

  let(:error_result) do
    instance_double(
      'Braintree::ErrorResult',
      success?: false,
      errors: [error],
      transaction: failed_transaction,
      params: { some: 'error' }
    )
  end

  let(:error_response) do
    described_class.build(error_result)
  end

  let(:successful_result) do
    transaction = instance_double(
      'Braintree::Transaction',
      status: 'ok',
      id: 'abcdef',
      avs_error_response_code: nil,
      avs_street_address_response_code: 'M',
      avs_postal_code_response_code: 'M',
      cvv_response_code: 'I'
    )

    instance_double(
      'Braintree::SuccessfulResult',
      success?: true,
      transaction: transaction
    )
  end

  let(:successful_response) do
    described_class.build(successful_result)
  end

  describe '.new' do
    it 'is private' do
      expect { described_class.new }.to raise_error(/private method/)
    end
  end

  describe '.build' do
    it { expect(error_response).to be_a ActiveMerchant::Billing::Response }
    it { expect(successful_response).to be_a ActiveMerchant::Billing::Response }
  end

  describe '#success?' do
    it { expect(error_response.success?).to be false }
    it { expect(successful_response.success?).to be true }
  end

  describe "#message" do
    context "with a success response" do
      subject { successful_response.message }
      it { is_expected.to eq "ok" }
    end

    context "with an error response" do
      subject { error_response.message }

      context "with a Braintree error" do
        it { is_expected.to eq "Cannot refund a transaction unless it is settled. (12345)" }
      end

      context "with a settlement_declined status" do
        let(:error) { nil }
        let(:failed_transaction) do
          instance_double(
            'Braintree::Transaction',
            id: 'abcdef',
            status: "settlement_declined",
            processor_settlement_response_code: "4001",
            processor_settlement_response_text: "Settlement Declined",
            avs_error_response_code: nil,
            avs_street_address_response_code: nil,
            avs_postal_code_response_code: nil,
            cvv_response_code: nil
          )
        end

        it { is_expected.to eq "Settlement Declined (4001)" }
      end

      context "with a gateway_rejected status" do
        let(:error) { nil }
        let(:failed_transaction) do
          instance_double(
            'Braintree::Transaction',
            id: 'abcdef',
            status: "gateway_rejected",
            gateway_rejection_reason: "cvv",
            avs_error_response_code: nil,
            avs_street_address_response_code: nil,
            avs_postal_code_response_code: nil,
            cvv_response_code: nil
          )
        end

        it { is_expected.to eq "CVV check failed." }
      end

      context "with a processor_declined status" do
        let(:error) { nil }
        let(:failed_transaction) do
          instance_double(
            'Braintree::Transaction',
            id: 'abcdef',
            status: "processor_declined",
            processor_response_code: '2001',
            processor_response_text: 'Insufficient Funds',
            avs_error_response_code: nil,
            avs_street_address_response_code: nil,
            avs_postal_code_response_code: nil,
            cvv_response_code: nil
          )
        end

        it { is_expected.to eq "Insufficient Funds (2001)" }
      end

      context 'with other transaction status' do
        let(:error) { nil }
        let(:failed_transaction) do
          instance_double(
            'Braintree::Transaction',
            id: 'abcdef',
            status: "authorization_expired",
            avs_error_response_code: nil,
            avs_street_address_response_code: nil,
            avs_postal_code_response_code: nil,
            cvv_response_code: nil
          )
        end

        it { is_expected.to eq 'Payment authorization has expired.' }
      end

      context 'with other transaction status that is not translated' do
        let(:error) { nil }
        let(:failed_transaction) do
          instance_double(
            'Braintree::Transaction',
            id: 'abcdef',
            status: "something_bad_happened",
            avs_error_response_code: nil,
            avs_street_address_response_code: nil,
            avs_postal_code_response_code: nil,
            cvv_response_code: nil
          )
        end

        it { is_expected.to eq 'Something bad happened' }
      end
    end
  end

  describe '#avs_result' do
    context 'with a successful result' do
      subject { described_class.build(successful_result).avs_result }

      it 'includes AVS response code' do
        expect(subject['code']).to eq 'M'
      end

      it 'includes AVS response message' do
        expect(subject['message']).to eq 'Street address and postal code match.'
      end
    end

    context 'with an error result' do
      let(:failed_transaction) do
        instance_double(
          'Braintree::Transaction',
          id: 'abcdef',
          avs_error_response_code: 'E',
          avs_street_address_response_code: nil,
          avs_postal_code_response_code: nil,
          cvv_response_code: nil
        )
      end

      subject { described_class.build(error_result).avs_result }

      it 'includes AVS response code' do
        expect(subject['code']).to eq 'E'
      end

      it 'includes AVS response message' do
        expect(subject['message']).to eq 'AVS data is invalid or AVS is not allowed for this card type.'
      end

      context 'without transaction' do
        let(:failed_transaction) { nil }

        it 'includes no AVS response' do
          expect(subject['message']).to be_nil
          expect(subject['code']).to be_nil
        end
      end
    end
  end

  describe '#cvv_result' do
    context 'with a successful result' do
      subject { described_class.build(successful_result).cvv_result }

      it 'does not include CVV response code' do
        expect(subject['code']).to be_nil
      end

      it 'does not include CVV response message' do
        expect(subject['message']).to be_nil
      end
    end

    context 'with an error result' do
      let(:failed_transaction) do
        instance_double(
          'Braintree::Transaction',
          id: 'abcdef',
          avs_error_response_code: nil,
          avs_street_address_response_code: nil,
          avs_postal_code_response_code: nil,
          cvv_response_code: 'N'
        )
      end

      subject { described_class.build(error_result).cvv_result }

      it 'includes CVV response code' do
        expect(subject['code']).to eq 'N'
      end

      it 'includes CVV response message' do
        expect(subject['message']).to eq 'CVV does not match'
      end

      context 'without transaction' do
        let(:failed_transaction) { nil }

        it 'includes no CVV response' do
          expect(subject['message']).to be_nil
          expect(subject['code']).to be_nil
        end
      end
    end
  end

  describe '#params' do
    context "with an error response" do
      subject { error_response.params }

      it 'includes request params' do
        is_expected.to eq({ 'some' => 'error' })
      end
    end
  end

  describe '#authorization' do
    it 'is whatever the b.t. transaction id was' do
      expect(successful_response.authorization).to eq 'abcdef'
    end

    it { expect(error_response.authorization).to be_nil }
  end
end
