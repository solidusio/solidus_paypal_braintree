/**
 * Constructor for PayPal button object
 * @constructor
 * @param {object} element - The DOM element of your PayPal button
 */
function PaypalButton(element) {
  this.element = element;
}

/**
 * Creates the PayPal session using the provided options and enables the button
 *
 * @param {object} options - The options passed to tokenize when constructing
 *                           the PayPal instance
 *
 * See {@link https://braintree.github.io/braintree-web/3.9.0/PayPal.html#tokenize}
 */
PaypalButton.prototype.initialize = function(options) {
  var self = this;

  /* This sets the payment method id returned by fetchToken on the PaypalButton
   * instance so that we can use it to build the transaction params later. */
  SolidusPaypalBraintree.fetchToken(function(token, paymentMethodId) {
    self.paymentMethodId = paymentMethodId;

    SolidusPaypalBraintree.initializeWithDataCollector(token, function(client) {
      self.createPaypalInstance(client, function(paypal) {

        self.initializePaypalSession({
          paypalInstance: paypal,
          paypalButton: self.element,
          paypalOptions: options
        }, self.tokenizeCallback.bind(self));
      });

    });
  });
};

PaypalButton.prototype.createPaypalInstance = function(braintreeClient, readyCallback) {
  braintree.paypal.create({
    client: braintreeClient
  }, function (paypalErr, paypalInstance) {
    if (paypalErr) {
      console.error("Error creating PayPal:", paypalErr);
      return;
    }
    readyCallback(paypalInstance);
  });
};

/* Initializes and begins the Paypal session
 *
 * @param config Configuration settings for the session
 * @param config.paypalInstance {object} The Paypal instance returned by Braintree
 * @param config.paypalButton {object} The button DOM element
 * @param config.paypalOptions {object} Configuration options for Paypal
 * @param config.error {tokenizeErrorCallback} Callback function for tokenize errors
 * @param {tokenizeCallback} callback Callback function for tokenization
 */
PaypalButton.prototype.initializePaypalSession = function(config, callback) {
    config.paypalButton.removeAttribute('disabled');
    config.paypalButton.addEventListener('click', function(event) {
      config.paypalInstance.tokenize(config.paypalOptions, callback);
    }, false);
  },

/**
 * Default callback function for when tokenization completes
 *
 * @param {object|null} tokenizeErr - The error returned by Braintree on failure
 * @param {object} payload - The payload returned by Braintree on success
 */
PaypalButton.prototype.tokenizeCallback = function(tokenizeErr, payload) {
  if (tokenizeErr) {
    console.error('Error tokenizing:', tokenizeErr);
  } else {
    var params = this.transactionParams(payload);

    Spree.ajax({
      url: Spree.pathFor("solidus_paypal_braintree/transactions"),
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
  }
};

/**
 * Assigns a new callback function for when tokenization completes
 *
 * @callback callback - The callback function to assign
 */
PaypalButton.prototype.setTokenizeCallback = function(callback) {
  this.tokenizeCallback = callback;
};

/**
 * Builds the transaction parameters to submit to Solidus for the given
 * payload returned by Braintree
 *
 * @param {object} payload - The payload returned by Braintree after tokenization
 */
PaypalButton.prototype.transactionParams = function(payload) {
  return {
    "payment_method_id" : this.paymentMethodId,
    "transaction" : {
      "email" : payload.details.email,
      "phone" : payload.details.phone,
      "nonce" : payload.nonce,
      "payment_type" : payload.type,
      "address_attributes" : this.addressParams(payload)
    }
  }
};

/**
 * Builds the address parameters to submit to Solidus using the payload
 * returned by Braintree
 *
 * @param {object} payload - The payload returned by Braintree after tokenization
 */
PaypalButton.prototype.addressParams = function(payload) {
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

$(document).ready(function() {
  if (document.getElementById("empty-cart")) {
    $.when(
      $.getScript("https://js.braintreegateway.com/web/3.9.0/js/client.min.js"),
      $.getScript("https://js.braintreegateway.com/web/3.9.0/js/paypal.min.js"),
      $.getScript("https://js.braintreegateway.com/web/3.9.0/js/data-collector.min.js")
    ).done(function() {
      $('<script/>').attr({
        'data-merchant' : "braintree",
        'data-id' : "paypal-button",
        'data-button' : "checkout",
        'data-color' : "blue",
        'data-size' : "medium",
        'data-shape' : "pill",
        'data-button_type' : "button",
        'data-button_disabled' : "true"
      }).
      load(function() {
        var button = new PaypalButton(document.querySelector("#paypal-button"));
        button.initialize({
          flow: 'vault',
          enableShippingAddress: true,
        });
      }).
      insertAfter("#content").
      attr('src', 'https://www.paypalobjects.com/api/button.js?')
    });
  }
});
