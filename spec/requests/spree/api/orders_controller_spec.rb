require 'spec_helper'

describe Spree::Api::OrdersController, type: :request do
  describe 'GET show' do
    context 'can render the payment source view for each gateway' do
      include_context 'order ready for payment'

      before do
        @current_api_user = order.user
        stub_authentication!
        order.payments.create!(
          payment_method: gateway,
          amount: order.total,
          state: 'completed',
          source: SolidusPaypalBraintree::Source.create!(
            payment_method: gateway,
            payment_type: SolidusPaypalBraintree::Source::CREDIT_CARD,
            user: order.user,
            nonce: 'fake-nonce',
            token: 'abcdef123456'
          )
        )
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
