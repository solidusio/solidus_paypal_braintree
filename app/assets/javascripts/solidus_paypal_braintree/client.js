SolidusPaypalBraintree.Client = function(config) {
  this.paymentMethodId = config.paymentMethodId;
  this.readyCallback = config.readyCallback;
  this.useDataCollector = config.useDataCollector;
  this.usePaypal = config.usePaypal;

  this._braintreeInstance = null;
  this._dataCollectorInstance = null;
  this._paypalInstance = null;
};

SolidusPaypalBraintree.Client.prototype.initialize = function() {
  var initializationPromise = this._fetchToken().
    then(this._createBraintreeInstance.bind(this))

  if(this.useDataCollector) {
    initializationPromise = initializationPromise.then(this._createDataCollector.bind(this));
  }

  if(this.usePaypal) {
    initializationPromise = initializationPromise.then(this._createPaypal.bind(this));
  }

  return initializationPromise.then(this._invokeReadyCallback.bind(this));
}

SolidusPaypalBraintree.Client.prototype.getBraintreeInstance = function() {
  return this._braintreeInstance;
}

SolidusPaypalBraintree.Client.prototype.getPaypalInstance = function() {
  return this._paypalInstance;
}

SolidusPaypalBraintree.Client.prototype.getDataCollectorInstance = function() {
  return this._dataCollectorInstance;
}


SolidusPaypalBraintree.Client.prototype._fetchToken = function() {
  var payload = {
    dataType: 'json',
    type: 'POST',
    url: SolidusPaypalBraintree.config.paths.clientTokens,
    error: function(xhr) {
      console.error("Error fetching braintree token");
    }
  }

  if (this.paymentMethodId) {
    payload.data = {
      payment_method_id: this.paymentMethodId
    };
  }

  return Spree.ajax(payload);
}

SolidusPaypalBraintree.Client.prototype._createBraintreeInstance = function(tokenResponse) {
  this.paymentMethodId = tokenResponse.payment_method_id;

  return SolidusPaypalBraintree.PromiseShim.convertBraintreePromise(braintree.client.create, [{
    authorization: tokenResponse.client_token
  }]).then(function (clientInstance) {
    this._braintreeInstance = clientInstance;
    return clientInstance;
  }.bind(this));
};

SolidusPaypalBraintree.Client.prototype._invokeReadyCallback = function() {
  if(this.readyCallback) {
    this.readyCallback(this._braintreeInstance);
  }

  return this;
}

SolidusPaypalBraintree.Client.prototype._createDataCollector = function() {
  return SolidusPaypalBraintree.PromiseShim.convertBraintreePromise(braintree.dataCollector.create, [{
    client: this._braintreeInstance,
    paypal: !!this.usePaypal
  }]).then(function (dataCollectorInstance) {
    this._dataCollectorInstance = dataCollectorInstance;
    return dataCollectorInstance;
  }.bind(this));
}

SolidusPaypalBraintree.Client.prototype._createPaypal = function() {
  return SolidusPaypalBraintree.PromiseShim.convertBraintreePromise(braintree.paypal.create, [{
    client: this._braintreeInstance
  }]).then(function (paypalInstance) {
    this._paypalInstance = paypalInstance;
    return paypalInstance;
  }.bind(this));
}

SolidusPaypalBraintree.Client.prototype.setupApplePay = function(braintreeClient, merchantId, readyCallback) {
  if(window.ApplePaySession && location.protocol == "https:") {
    var promise = ApplePaySession.canMakePaymentsWithActiveCard(merchantId);
    promise.then(function (canMakePayments) {
      if (canMakePayments) {
        braintree.applePay.create({
          client: braintreeClient
        }, function (applePayErr, applePayInstance) {
          if (applePayErr) {
            console.error("Error creating ApplePay:", applePayErr);
            return;
          }
          readyCallback(applePayInstance);
        });
      }
    });
  };
}

/* Initializes and begins the ApplePay session
 *
 * @param config Configuration settings for the session
 * @param config.applePayInstance {object} The instance returned from applePay.create
 * @param config.storeName {String} The name of the store
 * @param config.paymentRequest {object} The payment request to submit
 * @param config.currentUserEmail {String|undefined} The active user's email
 * @param config.paymentMethodId {Integer} The SolidusPaypalBraintree::Gateway id
 */
SolidusPaypalBraintree.Client.prototype.initializeApplePaySession = function(config, sessionCallback) {
  var requiredFields = ['postalAddress', 'phone'];

  if (!config.currentUserEmail) {
    requiredFields.push('email');
  }

  config.paymentRequest['requiredShippingContactFields'] = requiredFields
  var paymentRequest = config.applePayInstance.createPaymentRequest(config.paymentRequest);

  var session = new ApplePaySession(SolidusPaypalBraintree.APPLE_PAY_API_VERSION, paymentRequest);
  session.onvalidatemerchant = function (event) {
    config.applePayInstance.performValidation({
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
    config.applePayInstance.tokenize({
      token: event.payment.token
    }, function (tokenizeErr, payload) {
      if (tokenizeErr) {
        console.error('Error tokenizing Apple Pay:', tokenizeErr);
        session.completePayment(ApplePaySession.STATUS_FAILURE);
      }

      var contact = event.payment.shippingContact;

      Spree.ajax({
        data: this._buildTransaction(payload, config, contact),
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

  sessionCallback(session);

  session.begin();
},

SolidusPaypalBraintree.Client.prototype._buildTransaction = function(payload, config, shippingContact) {
  return {
    transaction: {
      nonce: payload.nonce,
      phone: shippingContact.phoneNumber,
      email: config.currentUserEmail || shippingContact.emailAddress,
      payment_type: payload.type,
      address_attributes: this._buildAddress(shippingContact)
    },
    payment_method_id: config.paymentMethodId
  };
},

SolidusPaypalBraintree.Client.prototype._buildAddress = function(shippingContact) {
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
    addressHash['address_line_2'] = shippingContact.addressLines[1];
  }

  return addressHash;
}
