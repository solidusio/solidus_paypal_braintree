require 'spec_helper'

describe Spree::Api::OrdersController, type: :request do

  vcr_attrs =
    if Gem::Requirement.new('>= 2.6').satisfied_by?(SolidusSupport.solidus_gem_version)
      {}
    else
      { vcr: { cassette_name: 'api/orders/show' } }
    end

  describe 'GET show', **vcr_attrs do
    context 'can render the payment source view for each gateway' do
      include_context 'order ready for payment'

      let(:payment_source) do
        SolidusPaypalBraintree::Source.create!(
          payment_method: gateway,
          payment_type: SolidusPaypalBraintree::Source::CREDIT_CARD,
          user: order.user,
          nonce: 'fake-nonce',
          token: 'abcdef123456'
        )
      end

      before do
        # allow_any_instance_of(SolidusPaypalBraintree::Source).to receive(:expiration_month).and_return(nil)
        @current_api_user = order.user
        stub_authentication!
        order.payments.create!(
          payment_method: gateway,
          amount: order.total,
          state: 'completed',
          source: payment_source
        )
        # expiration_month
        order.next!
        get spree.api_order_path(order, token: user.spree_api_key)
      end

      context 'for paypal_braintree payment' do
        it 'can be rendered correctly' do
          if Gem::Requirement.new('>= 2.6').satisfied_by?(SolidusSupport.solidus_gem_version)
            expect(response).to render_template partial: 'spree/api/payments/source_views/_paypal_braintree'
          else
            expect(response).to render_template 'spree/api/orders/show'
          end
        end
      end
    end
  end
end
