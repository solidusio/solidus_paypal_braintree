//= require solidus_paypal_braintree/paypal_button

// This is the PayPal button on the cart page
$(document).ready(function() {
  if (document.getElementById("empty-cart")) {
    $.when(
      $.getScript("https://js.braintreegateway.com/web/3.31.0/js/client.min.js"),
      $.getScript("https://js.braintreegateway.com/web/3.31.0/js/paypal.min.js"),
      $.getScript("https://js.braintreegateway.com/web/3.31.0/js/data-collector.min.js")
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
        var paypalOptions = {
          flow: 'vault',
          enableShippingAddress: true
        }
        var options = {
          restart_checkout: true
        }
        var button = new SolidusPaypalBraintree.createPaypalButton(
          document.querySelector("#paypal-button"),
          paypalOptions,
          options
        );
        return button.initialize();
      }).
      insertAfter("#content").
      attr('src', 'https://www.paypalobjects.com/api/button.js?')
    });
  }
});
