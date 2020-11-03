//= require solidus_paypal_braintree/constants

SolidusPaypalBraintree.PaypalMessaging = function(paypalOptions) {
  this._paypalOptions = paypalOptions || {};

  this._client = null;
};

SolidusPaypalBraintree.PaypalMessaging.prototype.initialize = function() {
  this._client = new SolidusPaypalBraintree.createClient({usePaypal: true});

  return this._client.initialize().then(this.initializeCallback.bind(this));
};

SolidusPaypalBraintree.PaypalMessaging.prototype.initializeCallback = function() {
  this._paymentMethodId = this._client.paymentMethodId;

  this._client.getPaypalInstance().loadPayPalSDK({
    currency: this._paypalOptions.currency,
    components: "messages"
  })
};
