require 'spec_helper'

describe Spree::Store do
  describe 'before_create :build_default_configuration' do
    context 'when a braintree_configuration record already exists' do
      it 'does not overwrite it' do
        store = build(:store)
        custom_braintree_configuration = store.build_braintree_configuration
        store.save!
        expect(store.braintree_configuration).to be custom_braintree_configuration
      end
    end
  end
end
