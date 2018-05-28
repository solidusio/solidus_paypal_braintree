//= require solidus_paypal_braintree/paypal_button

$(document).ready(function() {
  if (document.getElementById("empty-cart")) {
    $.when(
      $.getScript("https://js.braintreegateway.com/web/3.31.0/js/client.min.js"),
      $.getScript("https://js.braintreegateway.com/web/3.31.0/js/paypal-checkout.min.js"),
      $.getScript("https://js.braintreegateway.com/web/3.31.0/js/data-collector.min.js")
    ).done(function() {
      $("#content").append('<div id="paypal-button"/>');
      $('<script/>').attr({
        'data-version-4' : "true"
      }).
      load(function() {
        var paypalOptions = {
          flow: 'vault',
          enableShippingAddress: true
        };
        var button = new SolidusPaypalBraintree.createPaypalButton(document.querySelector("#paypal-button"), paypalOptions);
        return button.initialize();
      }).
      insertAfter("#content").
      attr('src', 'https://www.paypalobjects.com/api/checkout.js');
    });
  }
});
