require 'spec_helper'

RSpec.describe SolidusPaypalBraintree::Response do
  let(:error_result) do
    transaction = instance_double(
      'Braintree::Transaction',
      status: 'error'
    )

    instance_double(
      'Braintree::ErrorResult',
      success?: false,
      transaction: transaction
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

  describe '#authorization' do
    it 'is whatever the b.t. transaction id was' do
      expect(successful_response.authorization).to eq 'abcdef'
    end

    it { expect(error_response.authorization).to be_nil }
  end
end
