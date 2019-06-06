Spree::Store.class_eval do
  has_one :braintree_configuration, class_name: "SolidusPaypalBraintree::Configuration", dependent: :destroy

  before_create :build_default_configuration

  private

  def build_default_configuration
    build_braintree_configuration unless braintree_configuration
  end
end
