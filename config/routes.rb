Rails.application.routes.draw do
  namespace :solidus_paypal_braintree do
    resource :checkout, only: [:update, :edit]

    resource :transactions, only: [:create]
  end
end
