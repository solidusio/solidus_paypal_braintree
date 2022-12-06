SolidusBraintree = {
  APPLE_PAY_API_VERSION: 1,

  config: {
    paths: {
      clientTokens: Spree.pathFor('solidus_braintree/client_token'),
      transactions: Spree.pathFor('solidus_braintree/transactions')
    },

    // Override to provide your own error messages.
    braintreeErrorHandle: function(braintreeError) {
      BraintreeError.getErrorFromSlug(braintreeError.code);
      SolidusBraintree.showError(error);
    },

    classes: {
      hostedForm: function() {
        return SolidusBraintree.HostedForm;
      },

      client: function() {
        return SolidusBraintree.Client;
      },

      paypalButton: function() {
        return SolidusBraintree.PaypalButton;
      },

      paypalMessaging: function() {
        return SolidusBraintree.PaypalMessaging;
      },

      applepayButton: function() {
        return SolidusBraintree.ApplepayButton;
      },

      venmoButton: function() {
        return SolidusBraintree.VenmoButton;
      }
    }
  },

  showError: function(error) {
    var $contentContainer = $("#content");
    var $flash = $("<div class='flash error'>" + error + "</div>");
    $contentContainer.prepend($flash);
    $flash.show().delay(5000).fadeOut(500);
  },

  createHostedForm: function() {
    return SolidusBraintree._factory(SolidusBraintree.config.classes.hostedForm(), arguments);
  },

  createClient: function() {
    return SolidusBraintree._factory(SolidusBraintree.config.classes.client(), arguments);
  },

  createPaypalButton: function() {
    return SolidusBraintree._factory(SolidusBraintree.config.classes.paypalButton(), arguments);
  },

  createPaypalMessaging: function() {
    return SolidusBraintree._factory(SolidusBraintree.config.classes.paypalMessaging(), arguments);
  },

  createApplePayButton: function() {
    return SolidusBraintree._factory(SolidusBraintree.config.classes.applepayButton(), arguments);
  },

  createVenmoButton: function() {
    return SolidusBraintree._factory(SolidusBraintree.config.classes.venmoButton(), arguments);
  },

  _factory: function(klass, args) {
    var normalizedArgs = Array.prototype.slice.call(args);
    return new (Function.prototype.bind.apply(klass, [null].concat(normalizedArgs)));
  }
};

BraintreeError = {
  DEFAULT: "Something bad happened!",

  getErrorFromSlug: function(slug) {
    error = BraintreeError.DEFAULT
    if (slug in BraintreeError)
      error = BraintreeError[slug]
    return error
  }
}
