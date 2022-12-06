//= require solidus_braintree/constants

SolidusBraintree.PaypalMessaging = function(paypalOptions) {
  this._paypalOptions = paypalOptions || {};

  this._client = null;
};

SolidusBraintree.PaypalMessaging.prototype.initialize = function() {
  this._client = new SolidusBraintree.createClient({usePaypal: true});

  return this._client.initialize().then(this.initializeCallback.bind(this));
};

SolidusBraintree.PaypalMessaging.prototype.initializeCallback = function() {
  this._paymentMethodId = this._client.paymentMethodId;

  this._client.getPaypalInstance().loadPayPalSDK({
    currency: this._paypalOptions.currency,
    components: "messages"
  })
};
