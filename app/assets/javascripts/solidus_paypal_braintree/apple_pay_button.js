//= require solidus_paypal_braintree/constants
/**
 * Constructor for Apple Pay button object
 * @constructor
 * @param {object} element - The DOM element of your Apple Pay button
 */
SolidusPaypalBraintree.ApplepayButton = function(element, applepayOptions) {
  this._element = element;
  this._applepayOptions = applepayOptions || {};
  this._client = null;

  if(!this._element) {
    throw new Error("Element for the Apple Pay button must be present on the page");
  }
}

/**
 * Creates the Apple Pay session using the provided options and enables the button
 *
 * @param {object} options - The options passed to tokenize when constructing
 *                           the Apple Pay instance
 *
 * See {@link https://braintree.github.io/braintree-web/3.9.0/Apple Pay.html#tokenize}
 */
SolidusPaypalBraintree.ApplepayButton.prototype.initialize = function() {
  this._client = new SolidusPaypalBraintree.createClient(
    {
      useDataCollector: false, // TODO: I'm not sure whether this is a Paypal-only thing or not.
      useApplepay: true,
      paymentMethodId: this._applepayOptions.paymentMethodId
    }
  );
  return this._client.initialize().then(this.initializeCallback.bind(this));
};

SolidusPaypalBraintree.ApplepayButton.prototype.initializeCallback = function() {
  this._paymentMethodId = this._client.paymentMethodId;
  this._applePayInstance = this._client.getApplepayInstance();

  this._element.removeAttribute('disabled');
  this._element.style.display="block";
  this._element.addEventListener('click', function(event) {
    this.beginApplepayCheckout();
  }.bind(this), false);
};

SolidusPaypalBraintree.ApplepayButton.prototype.beginApplepayCheckout = function() {

  // countryCode
  // currencyCode
  // merchantCapabilities
  // supportedNetworks
  // ... are added by the Braintree gateway, but can be overridden
  // See https://developer.apple.com/documentation/applepayjs/applepaypaymentrequest
  var paymentRequest = this._applePayInstance.createPaymentRequest({
    total: {
      label: this._applepayOptions.storeName,
      amount: this._applepayOptions.amount
    },
    shippingContact: this._applepayOptions.shippingContact
    // lineItems
    // billingContact
    // shippingContact
    // applicationData
  });

  // TODO: rename currentUserEmail, as we're using the order email, which might be for a guest checkout without a current user
  this._client.initializeApplePaySession({
    applePayInstance: this._applePayInstance,
    storeName: this._applepayOptions.storeName,
    currentUserEmail: this._applepayOptions.orderEmail,
    paymentMethodId: this._paymentMethodId,
    paymentRequest: paymentRequest
  }, function(session) {
    // TODO: Apple Pay allows changing the shipping contact info and shipping method. If the user does this, we should update the order.
    // Add in your logic for onshippingcontactselected and onshippingmethodselected.
  });
};

/**
 * Builds the transaction parameters to submit to Solidus for the given
 * payload returned by Braintree
 *
 * @param {object} payload - The payload returned by Braintree after tokenization
 */
SolidusPaypalBraintree.ApplepayButton.prototype._transactionParams = function(payload) {
  return {
    "payment_method_id" : this._paymentMethodId,
    "transaction" : {
      "email" : payload.details.email,
      "phone" : payload.details.phone,
      "nonce" : payload.nonce,
      "payment_type" : payload.type,
      "address_attributes" : this._addressParams(payload)
    }
  }
};

/**
 * Builds the address parameters to submit to Solidus using the payload
 * returned by Braintree
 *
 * @param {object} payload - The payload returned by Braintree after tokenization
 */
SolidusPaypalBraintree.ApplepayButton.prototype._addressParams = function(payload) {
  if (payload.details.shippingAddress.recipientName) {
    var first_name = payload.details.shippingAddress.recipientName.split(" ")[0];
    var last_name = payload.details.shippingAddress.recipientName.split(" ")[1];
  }
  if (first_name == null || last_name == null) {
    var first_name = payload.details.firstName;
    var last_name = payload.details.lastName;
  }

  return {
    "first_name" : first_name,
    "last_name" : last_name,
    "address_line_1" : payload.details.shippingAddress.line1,
    "address_line_2" : payload.details.shippingAddress.line2,
    "city" : payload.details.shippingAddress.city,
    "state_code" : payload.details.shippingAddress.state,
    "zip" : payload.details.shippingAddress.postalCode,
    "country_code" : payload.details.shippingAddress.countryCode
  }
};
