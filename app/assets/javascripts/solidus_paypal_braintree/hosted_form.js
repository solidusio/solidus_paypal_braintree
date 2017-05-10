SolidusPaypalBraintree.HostedForm = function($paymentForm, $hostedFields, paymentMethodId) {
  this.paymentForm = $paymentForm;
  this.hostedFields = $hostedFields;
  this.paymentMethodId = paymentMethodId;
  this.client = null;
}

SolidusPaypalBraintree.HostedForm.prototype.initialize = function() {
  return SolidusPaypalBraintree.Client.fetchToken(this.paymentMethodId).
    then(this._setClient.bind(this))
}

SolidusPaypalBraintree.HostedForm.prototype._setClient = function(clientData) {
  this.client = new SolidusPaypalBraintree.Client(clientData.client_token);
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
