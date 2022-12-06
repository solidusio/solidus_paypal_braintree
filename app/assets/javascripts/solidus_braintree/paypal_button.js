//= require solidus_paypal_braintree/constants
/**
 * Constructor for PayPal button object
 * @constructor
 * @param {object} element - The DOM element of your PayPal button
 */
SolidusBraintree.PaypalButton = function(element, paypalOptions, options) {
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

  this._buyerCountry = this._paypalOptions.buyerCountry;
  delete paypalOptions['buyerCountry'];

  this._enabledFunding = [];

  if (paypalOptions['venmoFunding']) this._enabledFunding.push('venmo');
  delete paypalOptions['venmoFunding'];

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
SolidusBraintree.PaypalButton.prototype.initialize = function() {
  this._client = new SolidusBraintree.createClient({
      useDataCollector: this._paypalOptions.useDataCollector,
      usePaypal: true
  });

  return this._client.initialize().then(this.initializeCallback.bind(this));
};

SolidusBraintree.PaypalButton.prototype.initializeCallback = function() {
  this._paymentMethodId = this._client.paymentMethodId;

  var args = {
    "client-id": this._environment === "sandbox" ? "sb" : null,
    currency: this._paypalOptions.currency,
    commit: true,
    vault: this._paypalOptions.flow == "vault",
    components: this.style['messaging'] == "true" && this._paypalOptions.flow != "vault" ? "buttons,messages" : "buttons",
    intent: this._paypalOptions.flow == "vault" ? "tokenize" : "authorize"
  };

  if (this._environment === "sandbox" && this._buyerCountry) {
    args["buyer-country"] = this._buyerCountry
  }
  if (this._enabledFunding.length !== 0) {
    args["enable-funding"] = this._enabledFunding.join(',');
  }

  this._client.getPaypalInstance().loadPayPalSDK(args).then(() => {
    var create_method = this._paypalOptions.flow == "vault" ? "createBillingAgreement" : "createOrder"

    var render_config = {
      style: this.style,
      onClick: (data) => { SolidusBraintree.fundingSource = data.fundingSource },
      [create_method]: function () {
        return this._client.getPaypalInstance().createPayment(this._paypalOptions);
      }.bind(this),
      onApprove: function (data, actions) {
        return this._client.getPaypalInstance().tokenizePayment(data, this._tokenizeCallback.bind(this));
      }.bind(this)
    };

    paypal.Buttons(render_config).render(this._element);
  })
};

/**
 * Default callback function for when tokenization completes
 *
 * @param {object|null} tokenizeErr - The error returned by Braintree on failure
 * @param {object} payload - The payload returned by Braintree on success
 */
SolidusBraintree.PaypalButton.prototype._tokenizeCallback = function(tokenizeErr, payload) {
  if (tokenizeErr) {
    SolidusBraintree.config.braintreeErrorHandle(tokenizeErr);
    return;
  }

  var params = this._transactionParams(payload);

  return Spree.ajax({
    url: SolidusBraintree.config.paths.transactions,
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
      SolidusBraintree.showError(errorText);
    },
  });
};

/**
 * Builds the transaction parameters to submit to Solidus for the given
 * payload returned by Braintree
 *
 * @param {object} payload - The payload returned by Braintree after tokenization
 */
SolidusBraintree.PaypalButton.prototype._transactionParams = function(payload) {
  return {
    "payment_method_id" : this._paymentMethodId,
    "options": this._options,
    "transaction" : {
      "email" : payload.details.email,
      "phone" : payload.details.phone,
      "nonce" : payload.nonce,
      "payment_type" : payload.type,
      "paypal_funding_source": SolidusBraintree.fundingSource,
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
SolidusBraintree.PaypalButton.prototype._addressParams = function(payload) {
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
