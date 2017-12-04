SolidusPaypalBraintree = {
  APPLE_PAY_API_VERSION: 1,

  config: {
    paths: {
      clientTokens: Spree.pathFor('solidus_paypal_braintree/client_token'),
      transactions: Spree.pathFor('solidus_paypal_braintree/transactions')
    },

    // Override to provide your own error messages.
    braintreeErrorHandle: function(braintreeError) {
      BraintreeError.getErrorFromSlug(braintreeError.code);
      SolidusPaypalBraintree.showError(error);
    },

    classes: {
      hostedForm: function() {
        return SolidusPaypalBraintree.HostedForm;
      },

      client: function() {
        return SolidusPaypalBraintree.Client;
      },

      paypalButton: function() {
        return SolidusPaypalBraintree.PaypalButton;
      },

      applepayButton: function() {
        return SolidusPaypalBraintree.ApplepayButton;
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
    return SolidusPaypalBraintree._factory(SolidusPaypalBraintree.config.classes.hostedForm(), arguments);
  },

  createClient: function() {
    return SolidusPaypalBraintree._factory(SolidusPaypalBraintree.config.classes.client(), arguments);
  },

  createPaypalButton: function() {
    return SolidusPaypalBraintree._factory(SolidusPaypalBraintree.config.classes.paypalButton(), arguments);
  },

  createApplePayButton: function() {
    return SolidusPaypalBraintree._factory(SolidusPaypalBraintree.config.classes.applepayButton(), arguments);
  },

  _factory: function(klass, args) {
    var normalizedArgs = Array.prototype.slice.call(args);
    return new (Function.prototype.bind.apply(klass, [null].concat(normalizedArgs)));
  }
};
