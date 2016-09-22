// Placeholder manifest file.
// the installer will append this file to the app vendored assets here: vendor/assets/javascripts/spree/frontend/all.js'

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

  setupApplePay: function(braintreeClient, merchantId, readyCallback) {
    if(window.ApplePaySession) {
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

        shipping_contact = event.payment.shippingContact;
        address_hash = {
          country_code:   shipping_contact.countryCode,
          first_name:     shipping_contact.givenName,
          last_name:      shipping_contact.familyName,
          state_code:     shipping_contact.administrativeArea,
          city:           shipping_contact.locality,
          zip:            shipping_contact.postalCode,
          address_line_1: shipping_contact.addressLines[0]
        };

        if(shipping_contact.addressLines.length > 1) {
          address_hash['address_line_2'] = shipping_contact.addressLines[1];
        }

        transaction_params = {
          transaction: {
            nonce: payload.nonce,
            phone: shipping_contact.phoneNumber,
            email: config.currentUserEmail || shipping_contact.emailAddress,
            payment_type: payload.type,
            address_attributes: address_hash
          },
          payment_method_id: config.paymentMethodId
        };

        Spree.ajax({
          data: transaction_params,
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

              if (errors["Address"] || errors["TransactionAddress"]) {
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
  }
}
