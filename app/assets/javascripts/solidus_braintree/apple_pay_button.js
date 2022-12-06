//= require solidus_braintree/constants
/**
 * Constructor for Apple Pay button object
 * @constructor
 * @param {object} element - The DOM element of your Apple Pay button
 */
SolidusBraintree.ApplepayButton = function(element, applepayOptions) {
  this._element = element;
  this._applepayOptions = applepayOptions || {};
  this._client = null;

  if(!this._element) {
    throw new Error("Element for the Apple Pay button must be present on the page");
  }
};

/**
 * Creates the Apple Pay session using the provided options and enables the button
 *
 * @param {object} options - The options passed to tokenize when constructing
 *                           the Apple Pay instance
 *
 * See {@link https://braintree.github.io/braintree-web/3.9.0/Apple Pay.html#tokenize}
 */
SolidusBraintree.ApplepayButton.prototype.initialize = function() {
  if (window.ApplePaySession && ApplePaySession.canMakePayments()) {
    this._client = new SolidusBraintree.createClient(
      {
        useDataCollector: false,
        useApplepay: true,
        paymentMethodId: this._applepayOptions.paymentMethodId
      }
    );
    return this._client.initialize().then(this.initializeCallback.bind(this));
  }
};

SolidusBraintree.ApplepayButton.prototype.initializeCallback = function() {
  this._paymentMethodId = this._client.paymentMethodId;
  this._applePayInstance = this._client.getApplepayInstance();

  this._element.removeAttribute('disabled');
  this._element.classList.add("visible");
  this._element.addEventListener('click', function(event) {
    this.initializeApplePaySession();
    event.preventDefault();
  }.bind(this), false);
};

/**
 * Initialize and begin the ApplePay session
**/
SolidusBraintree.ApplepayButton.prototype.initializeApplePaySession = function() {
  var paymentRequest = this._applePayInstance.createPaymentRequest(this._paymentRequestHash());
  var session = new ApplePaySession(SolidusBraintree.APPLE_PAY_API_VERSION, paymentRequest);
  var applePayButton = this;

  session.onvalidatemerchant = function (event) {
    applePayButton.validateMerchant(session, paymentRequest);
  };

  session.onpaymentauthorized = function (event) {
    applePayButton.tokenize(session, event.payment);
  };

  session.begin();
};

SolidusBraintree.ApplepayButton.prototype.validateMerchant = function(session, paymentRequest) {
  this._applePayInstance.performValidation({
    validationURL: event.validationURL,
    displayName: paymentRequest.total.label,
  }, function (validationErr, merchantSession) {
    if (validationErr) {
      console.error('Error validating Apple Pay:', validationErr);
      session.abort();
      return;
    }
    session.completeMerchantValidation(merchantSession);
  });
};

SolidusBraintree.ApplepayButton.prototype.tokenize = function (session, payment) {
  this._applePayInstance.tokenize(
    {token: payment.token},
    function (tokenizeErr, payload) {
      if (tokenizeErr) {
        console.error('Error tokenizing Apple Pay:', tokenizeErr);
        session.completePayment(ApplePaySession.STATUS_FAILURE);
      }
      this._createTransaction(session, payment, payload);
    }.bind(this)
  );
};

SolidusBraintree.ApplepayButton.prototype._createTransaction = function (session, payment, payload) {
  Spree.ajax({
    data: this._transactionParams(payload, payment.shippingContact),
    dataType: 'json',
    type: 'POST',
    url: SolidusBraintree.config.paths.transactions,
    success: function(response) {
      session.completePayment(ApplePaySession.STATUS_SUCCESS);
      window.location.replace(response.redirectUrl);
    },
    error: function(xhr) {
      if (xhr.status === 422) {
        var errors = xhr.responseJSON.errors;

        if (errors && errors.Address) {
          session.completePayment(ApplePaySession.STATUS_INVALID_SHIPPING_POSTAL_ADDRESS);
        } else {
          session.completePayment(ApplePaySession.STATUS_FAILURE);
        }
      }
    }
  });
};

// countryCode
// currencyCode
// merchantCapabilities
// supportedNetworks
// ... are added by the Braintree gateway, but can be overridden
// See https://developer.apple.com/documentation/applepayjs/applepaypaymentrequest
SolidusBraintree.ApplepayButton.prototype._paymentRequestHash = function() {
  return {
    total: {
      label: this._applepayOptions.storeName,
      amount: this._applepayOptions.amount
    },
    shippingContact: this._applepayOptions.shippingContact,
    requiredShippingContactFields: ['postalAddress', 'phone', 'email']
  };
};

/**
 * Builds the transaction parameters to submit to Solidus for the given
 * payload returned by Braintree
 *
 * @param {object} payload - The payload returned by Braintree after tokenization
 */
SolidusBraintree.ApplepayButton.prototype._transactionParams = function(payload, shippingContact) {
  return {
    payment_method_id: this._applepayOptions.paymentMethodId,
    transaction: {
      email: shippingContact.emailAddress,
      nonce: payload.nonce,
      payment_type: payload.type,
      phone: shippingContact.phoneNumber,
      address_attributes: this._addressParams(shippingContact)
    }
  };
};

/**
 * Builds the address parameters to submit to Solidus using the payload
 * returned by Braintree
 *
 * @param {object} payload - The payload returned by Braintree after tokenization
 */
SolidusBraintree.ApplepayButton.prototype._addressParams = function(shippingContact) {
  var addressHash = {
    country_name:   shippingContact.country,
    country_code:   shippingContact.countryCode,
    first_name:     shippingContact.givenName,
    last_name:      shippingContact.familyName,
    state_code:     shippingContact.administrativeArea,
    city:           shippingContact.locality,
    zip:            shippingContact.postalCode,
    address_line_1: shippingContact.addressLines[0]
  };

  if(shippingContact.addressLines.length > 1) {
    addressHash.address_line_2 = shippingContact.addressLines[1];
  }

  return addressHash;
};
