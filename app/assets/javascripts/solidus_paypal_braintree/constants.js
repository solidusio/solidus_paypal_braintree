SolidusPaypalBraintree = {
  APPLY_PAY_API_VERSION: 1,

  config: {
    paths: {
      clientTokens: Spree.pathFor('solidus_paypal_braintree/client_token'),
      transactions: Spree.pathFor('solidus_paypal_braintree/transactions')
    },

    // Override to provide your own error messages.
    braintreeErrorHandle: function(braintreeError) {
      var $contentContainer = $("#content");
      var $flash = $("<div class='flash error'>" + braintreeError.name + ": " + braintreeError.message + "</div>");
      $contentContainer.prepend($flash);

      $flash.show().delay(5000).fadeOut(500);
    },

    hostedFormClass: function() {
      return SolidusPaypalBraintree.HostedForm;
    },

    clientClass: function() {
      return SolidusPaypalBraintree.Client;
    }
  },

  createHostedForm: function() {
    return SolidusPaypalBraintree._factory(SolidusPaypalBraintree.config.hostedFormClass(), arguments);
  },

  createClient: function() {
    return SolidusPaypalBraintree._factory(SolidusPaypalBraintree.config.clientClass(), arguments);
  },

  _factory: function(klass, args) {
    var normalizedArgs = Array.prototype.slice.call(args);
    return new (Function.prototype.bind.apply(klass, [null].concat(normalizedArgs)));
  }
};
