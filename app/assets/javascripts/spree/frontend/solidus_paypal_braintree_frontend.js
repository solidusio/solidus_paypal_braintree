initializePaypal = function(authToken, paymentMethodId) {
  window.paymentMethodId = paymentMethodId;
  window.SolidusPaypalBraintree.initializeWithDataCollector(authToken, function(clientInstance) {
    window.SolidusPaypalBraintree.setupPaypal(clientInstance, function(paypalInstance) {
      var paypalButton = document.querySelector('#paypal-button');
      if (document.querySelector('#shipping_address')) {
        var address = JSON.parse(document.querySelector('#shipping_address').value);
        var paypalOptions = {flow: 'vault', shippingAddressOverride: address, shippingAddressEditable: false, enableShippingAddress: true}
      } else {
        var paypalOptions = {flow: 'vault', enableShippingAddress: true}
      }
      window.SolidusPaypalBraintree.initializePaypalSession(paypalInstance, paypalButton, paypalOptions, submitBraintreeTransaction);
    });
  });
};

initializePaypalCredit = function(authToken, paymentMethodId) {
  window.paymentMethodId = paymentMethodId;
  window.SolidusPaypalBraintree.initializeWithDataCollector(authToken, function(clientInstance) {
    window.SolidusPaypalBraintree.setupPaypal(clientInstance, function(paypalInstance) {
      var paypalButton = document.querySelector('#paypal-credit-button');
      var address = JSON.parse(document.querySelector('#shipping_address').value);
      var paypalOptions = {flow: 'checkout', amount: amount, currency: currency, shippingAddressOverride: address, shippingAddressEditable: false, enableShippingAddress: true}
      window.SolidusPaypalBraintree.initializePaypalSession(paypalInstance, paypalButton, paypalOptions, submitBraintreeTransaction);
    });
  });
};

submitBraintreeTransaction = function(payload) {
  if (payload.details.shippingAddress.recipientName) {
    var first_name = payload.details.shippingAddress.recipientName.split(" ")[0];
    var last_name = payload.details.shippingAddress.recipientName.split(" ")[1];
  }
  if (first_name == null || last_name == null) {
    var first_name = payload.details.firstName;
    var last_name = payload.details.lastName;
  }
  var transactionParams = { "payment_method_id" : window.paymentMethodId,
                            "transaction" : { "email" : payload.details.email,
                                              "phone" : payload.details.phone,
                                              "nonce" : payload.nonce,
                                              "payment_type" : payload.type,
                                              "address_attributes" : { "first_name" : first_name,
                                                                       "last_name" : last_name,
                                                                       "address_line_1" : payload.details.shippingAddress.line1,
                                                                       "address_line_2" : payload.details.shippingAddress.line2,
                                                                       "city" : payload.details.shippingAddress.city,
                                                                       "state_code" : payload.details.shippingAddress.state,
                                                                       "zip" : payload.details.shippingAddress.postalCode,
                                                                       "country_code" : payload.details.shippingAddress.countryCode } } }
  Spree.ajax({
    url: Spree.pathFor("solidus_paypal_braintree/transactions"),
    type: 'POST',
    dataType: 'json',
    data: transactionParams,
    success: function(response) {
      window.location.href = Spree.pathFor("checkout/confirm");
    },
    error: function(xhr) {
      console.error("Error submitting transaction")
    },
  });
};

$(document).ready(function() {
  if (document.getElementById("empty-cart")) {
    $.when(
      $.getScript("https://js.braintreegateway.com/web/3.4.0/js/client.min.js"),
      $.getScript("https://js.braintreegateway.com/web/3.4.0/js/paypal.min.js"),
      $.getScript("https://js.braintreegateway.com/web/3.4.0/js/data-collector.min.js"),
      $.Deferred(function( deferred ){
        $( deferred.resolve );
      })
    ).done(function() {
      $(window).load(function() {
        $('<script/>').attr({
          'src' : 'https://www.paypalobjects.com/api/button.js?',
          'data-merchant' : "braintree",
          'data-id' : "paypal-button",
          'data-button' : "checkout",
          'data-color' : "blue",
          'data-size' : "medium",
          'data-shape' : "pill",
          'data-button_type' : "button",
          'data-button_disabled' : "true"
        }).insertAfter("#content");
        window.SolidusPaypalBraintree.fetchToken(initializePaypal)
      });
    });
  }
});
