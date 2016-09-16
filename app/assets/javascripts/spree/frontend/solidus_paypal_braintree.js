// Placeholder manifest file.
// the installer will append this file to the app vendored assets here: vendor/assets/javascripts/spree/frontend/all.js'

window.SolidusPaypalBraintree = {
  APPLE_PAY_API_VERSION: 1,

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

  initializeApplePaySession: function(applePayInstance, storeName, paymentRequest, sessionCallback) {

    var requiredFields = ['postalAddress', 'phone'];
    var currentUserEmail = document.querySelector("#transaction_email").value;

    if (!currentUserEmail) {
      requiredFields.push('email');
    }

    paymentRequest['requiredShippingContactFields'] = requiredFields
    var paymentRequest = applePayInstance.createPaymentRequest(paymentRequest);

    var session = new ApplePaySession(SolidusPaypalBraintree.APPLE_PAY_API_VERSION, paymentRequest);
    session.onvalidatemerchant = function (event) {
      applePayInstance.performValidation({
        validationURL: event.validationURL,
        displayName: storeName,
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
        session.completePayment(ApplePaySession.STATUS_SUCCESS);

        SolidusPaypalBraintree.setBraintreeApplePayContact(event.payment.shippingContact);
        SolidusPaypalBraintree.submitBraintreePayload(payload);
      });
    };

    sessionCallback(session);

    session.begin();
  },

  setBraintreeApplePayContact: function(appleContact) {
    var apple_map = {
      locality: 'city',
      countryCode: 'country_code',
      familyName: 'last_name',
      givenName: 'first_name',
      postalCode: 'zip',
      administrativeArea: 'state_code',
    }
    for (var key in apple_map) {
      document.querySelector("#transaction_address_attributes_" + apple_map[key]).value = appleContact[key];
    }

    window.addressCon = appleContact;
    document.querySelector("#transaction_address_attributes_address_line_1").value = appleContact.addressLines[0];

    if(appleContact.addressLines.length > 1) {
      document.querySelector("#transaction_address_attributes_address_line_2").value = appleContact.addressLines[1];
    }

    document.querySelector("#transaction_phone").value = appleContact.phoneNumber;
    if (appleContact.emailAddress) {
      document.querySelector("#transaction_email").value = appleContact.emailAddress;
    }
  },

  submitBraintreePayload: function(payload) {
    document.querySelector("#transaction_nonce").value = payload.nonce;
    document.querySelector("#transaction_payment_type").value = payload.type;
    document.querySelector('#new_transaction').submit();
  }
}
