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
      useDataCollector: false,
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
    this.initializeApplePaySession();
  }.bind(this), false);
};

/**
 * Initializes and begins the ApplePay session
 *
 * @param {Object} config Configuration settings for the session
 * @param {Object} config.applePayInstance The instance returned from applePay.create
 * @param {String} config.storeName The name of the store
 * @param {Object} config.paymentRequest The payment request to submit
 * @param {String} [config.orderEmail] The order's email
 * @param {Integer} config.paymentMethodId The SolidusPaypalBraintree::Gateway Id from the backend
**/
SolidusPaypalBraintree.ApplepayButton.prototype.initializeApplePaySession = function() {
  var config = {
    storeName: this._applepayOptions.storeName,
    orderEmail: this._applepayOptions.orderEmail,
    paymentMethodId: this._paymentMethodId,
  };

  // countryCode
  // currencyCode
  // merchantCapabilities
  // supportedNetworks
  // ... are added by the Braintree gateway, but can be overridden
  // See https://developer.apple.com/documentation/applepayjs/applepaypaymentrequest
  var paymentRequestHash = {
    total: {
      label: this._applepayOptions.storeName,
      amount: this._applepayOptions.amount
    },
    shippingContact: this._applepayOptions.shippingContact
    // lineItems
    // billingContact
    // shippingContact
    // applicationData
  };

  var requiredFields = ['postalAddress', 'phone'];

  if (!config.orderEmail) {
    requiredFields.push('email');
  }

  paymentRequestHash['requiredShippingContactFields'] = requiredFields

  var applePayInstance = this._applePayInstance;
  var paymentRequest = applePayInstance.createPaymentRequest(paymentRequestHash);

  var session = new ApplePaySession(SolidusPaypalBraintree.APPLE_PAY_API_VERSION, paymentRequest);

  session.onvalidatemerchant = function (event) {
    applePayInstance.performValidation({
      validationURL: event.validationURL,
      displayName: config.storeName,
    }, function (validationErr, merchantSession) {
      if (validationErr) {
        console.error('Error validating Apple Pay:', validationErr);
        session.abort();
        return;
      };
      session.completeMerchantValidation(merchantSession);
    });
  };

  session.onpaymentauthorized = function (event) {
    applePayInstance.tokenize({
      token: event.payment.token
    }, function (tokenizeErr, payload) {
      if (tokenizeErr) {
        console.error('Error tokenizing Apple Pay:', tokenizeErr);
        session.completePayment(ApplePaySession.STATUS_FAILURE);
      }

      var contact = event.payment.shippingContact;
      var params = SolidusPaypalBraintree.ApplepayButton.transactionParams(payload, config, contact);

      Spree.ajax({
        data: params,
        dataType: 'json',
        type: 'POST',
        url: SolidusPaypalBraintree.config.paths.transactions,
        success: function(response) {
          session.completePayment(ApplePaySession.STATUS_SUCCESS);
          window.location.replace(response.redirectUrl);
        },
        error: function(xhr) {
          if (xhr.status === 422) {
            var errors = xhr.responseJSON.errors

            if (errors && errors["Address"]) {
              session.completePayment(ApplePaySession.STATUS_INVALID_SHIPPING_POSTAL_ADDRESS);
            } else {
              session.completePayment(ApplePaySession.STATUS_FAILURE);
            }
          }
        }
      });

    });
  };

  session.begin();
},


/**
 * Builds the transaction parameters to submit to Solidus for the given
 * payload returned by Braintree
 *
 * @param {object} payload - The payload returned by Braintree after tokenization
 */
SolidusPaypalBraintree.ApplepayButton.transactionParams = function(payload, config, shippingContact) {
  return {
    payment_method_id: config.paymentMethodId,
    transaction: {
      email: config.orderEmail || shippingContact.emailAddress,
      nonce: payload.nonce,
      payment_type: payload.type,
      phone: shippingContact.phoneNumber,
      address_attributes: this.addressParams(shippingContact)
    }
  };
};

/**
 * Builds the address parameters to submit to Solidus using the payload
 * returned by Braintree
 *
 * @param {object} payload - The payload returned by Braintree after tokenization
 */
SolidusPaypalBraintree.ApplepayButton.addressParams = function(shippingContact) {
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
