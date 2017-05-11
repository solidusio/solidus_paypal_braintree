$(document).ready(function() {
  if (document.getElementById("empty-cart")) {
    $.when(
      $.getScript("https://js.braintreegateway.com/web/3.14.0/js/client.min.js"),
      $.getScript("https://js.braintreegateway.com/web/3.14.0/js/paypal.min.js"),
      $.getScript("https://js.braintreegateway.com/web/3.14.0/js/data-collector.min.js")
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
        var button = new SolidusPaypalBraintree.PaypalButton(document.querySelector("#paypal-button"));
        button.initialize({
          flow: 'vault',
          enableShippingAddress: true,
        });
      }).
      insertAfter("#content").
      attr('src', 'https://www.paypalobjects.com/api/button.js?')
    });
  }
});
