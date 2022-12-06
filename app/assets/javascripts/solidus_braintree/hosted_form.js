SolidusBraintree.HostedForm = function(paymentMethodId) {
  this.paymentMethodId = paymentMethodId;
  this.client = null;
};

SolidusBraintree.HostedForm.prototype.initialize = function() {
  this.client = SolidusBraintree.createClient({
    paymentMethodId: this.paymentMethodId,
    useThreeDSecure: (typeof(window.threeDSecureOptions) !== 'undefined'),
  });

  return this.client.initialize().
    then(this._createHostedFields.bind(this));
};

SolidusBraintree.HostedForm.prototype._createHostedFields = function () {
  if (!this.client) {
    throw new Error("Client not initialized, please call initialize first!");
  }

  var opts = {
    _solidusClient: this.client,
    client: this.client.getBraintreeInstance(),

    fields: {
      number: {
        selector: "#card_number" + this.paymentMethodId,
        placeholder: placeholder_text["number"]
      },

      cvv: {
        selector: "#card_code" + this.paymentMethodId,
        placeholder: placeholder_text["cvv"]
      },

      expirationDate: {
        selector: "#card_expiry" + this.paymentMethodId,
        placeholder: placeholder_text["expirationDate"]
      }
    },

    styles: credit_card_fields_style
  };

  return SolidusBraintree.PromiseShim.convertBraintreePromise(braintree.hostedFields.create, [opts]);
};
