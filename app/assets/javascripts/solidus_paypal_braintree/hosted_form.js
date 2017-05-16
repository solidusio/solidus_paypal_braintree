SolidusPaypalBraintree.HostedForm = function(paymentMethodId) {
  this.paymentMethodId = paymentMethodId;
  this.client = null;
}

SolidusPaypalBraintree.HostedForm.prototype.initialize = function() {
  this.client = SolidusPaypalBraintree.createClient({paymentMethodId: this.paymentMethodId});
  return this.client.initialize();
}

SolidusPaypalBraintree.HostedForm.prototype.createHostedFields = function () {
  if (!this.client) {
    throw new Error("Client not initialized, please call initialize first!");
  }

  var opts = {
    client: this.client.getBraintreeInstance(),

    fields: {
      number: {
        selector: "#card_number" + this.paymentMethodId
      },

      cvv: {
        selector: "#card_code" + this.paymentMethodId
      },

      expirationDate: {
        selector: "#card_expiry" + this.paymentMethodId
      }
    }
  };

  return SolidusPaypalBraintree.PromiseShim.convertBraintreePromise(braintree.hostedFields.create, [opts]);
}
