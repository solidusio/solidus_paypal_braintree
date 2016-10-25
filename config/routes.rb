Rails.application.routes.draw do
  namespace :solidus_paypal_braintree do
    resource :checkout, only: [:update, :edit]
    resource :client_token, only: [:create], format: :json
    resource :transactions, only: [:create]
  end
end
