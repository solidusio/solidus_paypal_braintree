//= require spree/braintree_hosted_form

//= require ../braintree_3_5_0_client
//= require ../braintree_3_5_0_paypal
//= require ../braintree_3_5_0_data_collector

window.SolidusPaypalBraintree = {
  APPLE_PAY_API_VERSION: 1,

  fetchToken: function(tokenCallback) {
    Spree.ajax({
      dataType: 'json',
      type: 'POST',
      url: Spree.pathFor('solidus_paypal_braintree/client_token'),
      success: function(response) {
        tokenCallback(response.client_token, response.payment_method_id);
      },
      error: function(xhr) {
        console.error("Error fetching braintree token");
      }
    });
  },

  initialize: function(authToken, clientReadyCallback) {
    braintree.client.create({
      authorization: authToken
    }, function (clientErr, clientInstance) {
      if (clientErr) {
        console.error('Error creating client:', clientErr);
        return;
      }
      clientReadyCallback(clientInstance);
    });
  },

  initializeWithDataCollector: function(authToken, clientReadyCallback) {
    braintree.client.create({
      authorization: authToken
    }, function (clientErr, clientInstance) {
      braintree.dataCollector.create({
        client: clientInstance,
        paypal: true
      }, function (err, dataCollectorInstance) {
        if (err) {
          console.error('Error creating data collector:', err);
          return;
        }
      });
      if (clientErr) {
        console.error('Error creating client:', clientErr);
        return;
      }
      clientReadyCallback(clientInstance);
    });
  },

  setupApplePay: function(braintreeClient, merchantId, readyCallback) {
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
  },

  /* Initializes and begins the ApplePay session
   *
   * @param config Configuration settings for the session
   * @param config.applePayInstance {object} The instance returned from applePay.create
   * @param config.storeName {String} The name of the store
   * @param config.paymentRequest {object} The payment request to submit
   * @param config.currentUserEmail {String|undefined} The active user's email
   * @param config.paymentMethodId {Integer} The SolidusPaypalBraintree::Gateway id
   */
  initializeApplePaySession: function(config, sessionCallback) {

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
          data: SolidusPaypalBraintree.buildTransaction(payload, config, contact),
          dataType: 'json',
          type: 'POST',
          url: Spree.pathFor('solidus_paypal_braintree/transactions'),
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

  buildTransaction: function(payload, config, shippingContact) {
    return {
      transaction: {
        nonce: payload.nonce,
        phone: shippingContact.phoneNumber,
        email: config.currentUserEmail || shippingContact.emailAddress,
        payment_type: payload.type,
        address_attributes: SolidusPaypalBraintree.buildAddress(shippingContact)
      },
      payment_method_id: config.paymentMethodId
    };
  },

  buildAddress: function(shippingContact) {
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
}
