//= require solidus_paypal_braintree/constants
/**
 * Constructor for PayPal button object
 * @constructor
 * @param {object} element - The DOM element of your PayPal button
 */
SolidusPaypalBraintree.PaypalButton = function(element, paypalOptions) {
  this._element = element;
  this._paypalOptions = paypalOptions || {};
  this._client = null;

  if(!this._element) {
    throw new Error("Element for the paypal button must be present on the page");
  }
}

/**
 * Creates the PayPal session using the provided options and enables the button
 *
 * @param {object} options - The options passed to tokenize when constructing
 *                           the PayPal instance
 *
 * See {@link https://braintree.github.io/braintree-web/3.9.0/PayPal.html#tokenize}
 */
SolidusPaypalBraintree.PaypalButton.prototype.initialize = function() {
  this._client = new SolidusPaypalBraintree.Client({useDataCollector: true, usePaypal: true});

  return this._client.initialize().then(this.initializeCallback.bind(this));
};

SolidusPaypalBraintree.PaypalButton.prototype.initializeCallback = function() {
  this._paymentMethodId = this._client.paymentMethodId;

  this._element.removeAttribute('disabled');
  this._element.addEventListener('click', function(event) {
    this._client.getPaypalInstance().tokenize(this._paypalOptions, this._tokenizeCallback.bind(this));
  }.bind(this), false);
};

/**
 * Default callback function for when tokenization completes
 *
 * @param {object|null} tokenizeErr - The error returned by Braintree on failure
 * @param {object} payload - The payload returned by Braintree on success
 */
SolidusPaypalBraintree.PaypalButton.prototype._tokenizeCallback = function(tokenizeErr, payload) {
  if (tokenizeErr) {
    SolidusPaypalBraintree.config.braintreeErrorHandle(tokenizeErr);
    return;
  }

  var params = this._transactionParams(payload);

  return Spree.ajax({
    url: SolidusPaypalBraintree.config.paths.transactions,
    type: 'POST',
    dataType: 'json',
    data: params,
    success: function(response) {
      window.location.href = response.redirectUrl;
    },
    error: function(xhr) {
      console.error("Error submitting transaction")
    },
  });
};

/**
 * Builds the transaction parameters to submit to Solidus for the given
 * payload returned by Braintree
 *
 * @param {object} payload - The payload returned by Braintree after tokenization
 */
SolidusPaypalBraintree.PaypalButton.prototype._transactionParams = function(payload) {
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
SolidusPaypalBraintree.PaypalButton.prototype._addressParams = function(payload) {
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

