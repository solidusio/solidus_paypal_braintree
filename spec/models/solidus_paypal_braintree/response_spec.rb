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
      transaction: failed_transaction
    )
  end

  let(:error_response) do
    described_class.build(error_result)
  end

  let(:successful_result) do
    transaction = instance_double(
      'Braintree::Transaction',
      status: 'ok',
      id: 'abcdef'
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

      context "with a processor error" do
        let(:error) { nil }
        let(:failed_transaction) do
          instance_double(
            'Braintree::Transaction',
            status: "settlement_declined",
            gateway_rejection_reason: nil,
            processor_settlement_response_code: "4001",
            processor_settlement_response_text: "Settlement Declined"
          )
        end

        it { is_expected.to eq "settlement_declined 4001 Settlement Declined" }
      end

      context "with a gateway error" do
        let(:error) { nil }
        let(:failed_transaction) do
          instance_double(
            'Braintree::Transaction',
            status: "gateway_rejected",
            gateway_rejection_reason: "cvv",
            processor_settlement_response_code: nil,
            processor_settlement_response_text: nil
          )
        end

        it { is_expected.to eq "gateway_rejected cvv" }
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
