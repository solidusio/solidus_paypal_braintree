//= require solidus_paypal_braintree/constants
/**
 * Constructor for PayPal button object
 * @constructor
 * @param {object} element - The DOM element of your PayPal button
 */
SolidusPaypalBraintree.PaypalButton = function(element, paypalOptions, options) {
  this._element = element;
  this._paypalOptions = paypalOptions || {};

  this.locale = paypalOptions['locale'] || "en_US";
  this.style = paypalOptions['style'] || {};
  delete paypalOptions['locale'];
  delete paypalOptions['style'];

  this._options = options || {};
  this._client = null;
  this._environment = this._paypalOptions.environment || 'sandbox';
  delete this._paypalOptions.environment;

  if(!this._element) {
    throw new Error("Element for the paypal button must be present on the page");
  }
};

/**
 * Creates the PayPal session using the provided options and enables the button
 *
 * @param {object} options - The options passed to tokenize when constructing
 *                           the PayPal instance
 *
 * See {@link https://braintree.github.io/braintree-web/3.9.0/PayPal.html#tokenize}
 */
SolidusPaypalBraintree.PaypalButton.prototype.initialize = function() {
  this._client = new SolidusPaypalBraintree.createClient({useDataCollector: true, usePaypal: true});

  return this._client.initialize().then(this.initializeCallback.bind(this));
};

SolidusPaypalBraintree.PaypalButton.prototype.initializeCallback = function() {
  this._paymentMethodId = this._client.paymentMethodId;

  var render_options = {
    env: this._environment,
    locale: this.locale,
    style: this.style,
    payment: function () {
      return this._client.getPaypalInstance().createPayment(this._paypalOptions);
    }.bind(this),
    onAuthorize: function (data, actions) {
      return this._client.getPaypalInstance().tokenizePayment(data, this._tokenizeCallback.bind(this));
    }.bind(this)
  };

  paypal.Button.render(render_options, this._element);
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
      var errorText = BraintreeError.DEFAULT;

      if (xhr.responseJSON && xhr.responseJSON.errors) {
        var errors = [];
        $.each(xhr.responseJSON.errors, function(key, values) {
          $.each(values, function(index, value) {
            errors.push(key + " " + value)
          });
        });

        if (errors.length > 0)
          errorText = errors.join(", ");
      }

      console.error("Error submitting transaction: " + errorText);
      SolidusPaypalBraintree.showError(errorText);
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
    "options": this._options,
    "transaction" : {
      "email" : payload.details.email,
      "phone" : payload.details.phone,
      "nonce" : payload.nonce,
      "payment_type" : payload.type,
      "address_attributes" : this._addressParams(payload)
    }
  };
};

/**
 * Builds the address parameters to submit to Solidus using the payload
 * returned by Braintree
 *
 * @param {object} payload - The payload returned by Braintree after tokenization
 */
SolidusPaypalBraintree.PaypalButton.prototype._addressParams = function(payload) {
  var name;
  var payload_address = payload.details.shippingAddress || payload.details.billingAddress;
  if (!payload_address) return {};

  if (payload_address.recipientName) {
    name = payload_address.recipientName
  } else {
    name = payload.details.firstName + " " + payload.details.lastName;
  }

  return {
    "name" : name,
    "address_line_1" : payload_address.line1,
    "address_line_2" : payload_address.line2,
    "city" : payload_address.city,
    "state_code" : payload_address.state,
    "zip" : payload_address.postalCode,
    "country_code" : payload_address.countryCode
  };
};
