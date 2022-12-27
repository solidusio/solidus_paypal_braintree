require 'spec_helper'

RSpec.describe SolidusBraintree::ExtensionConfiguration do
  describe "#table_name_prefix" do
    it "is 'solidus_braintree_' by default" do
      expect(subject.table_name_prefix).to eq('solidus_braintree_')
    end

    it "is settable" do
      subject.table_name_prefix = 'solidus_paypal_braintree_'

      expect(subject.table_name_prefix).to eq('solidus_paypal_braintree_')
    end
  end
end
