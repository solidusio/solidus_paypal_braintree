Spree.user_class.class_eval do
  has_one :braintree_customer, class_name: 'SolidusPaypalBraintree::Customer',
                               inverse_of: :user
end
