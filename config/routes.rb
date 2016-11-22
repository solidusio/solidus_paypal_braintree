SolidusPaypalBraintree::Engine.routes.draw do
  resource :checkout, only: [:update, :edit]
  resource :client_token, only: [:create], format: :json
  resource :transactions, only: [:create]
end
