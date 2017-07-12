function BraintreeHostedForm($paymentForm, $hostedFields, paymentMethodId) {
  this.paymentForm = $paymentForm;
  this.hostedFields = $hostedFields;
  this.paymentMethodId = paymentMethodId;
}

BraintreeHostedForm.prototype.initializeHostedFields = function() {
  return this.getToken().
    then(this.createClient.bind(this)).
    then(this.createHostedFields());
};

BraintreeHostedForm.prototype.promisify = function (fn, args, self) {
  var d = $.Deferred();

  fn.apply(self || this, (args || []).concat(function (err, data) {
    if (err) d.reject(err);
    d.resolve(data);
  }));

  return d.promise();
};

BraintreeHostedForm.prototype.getToken = function () {
  var opts = {
    url: "/solidus_paypal_braintree/client_token",
    method: "POST",
    data: {
      payment_method_id: this.paymentMethodId
    },
  };

  function onSuccess(data) {
    return data.client_token;
  }

  return Spree.ajax(opts).then(onSuccess);
};

BraintreeHostedForm.prototype.createClient = function (token) {
  var opts = { authorization: token };
  return this.promisify(braintree.client.create, [opts]);
};

BraintreeHostedForm.prototype.createHostedFields = function () {
  var self = this;
  var id = this.paymentMethodId;

  return function(client) {
    var opts = {
      client: client,

      fields: {
        number: {
          selector: "#card_number" + id
        },

        cvv: {
          selector: "#card_code" + id
        },

        expirationDate: {
          selector: "#card_expiry" + id
        }
      }
    };

    return self.promisify(braintree.hostedFields.create, [opts]);
  };
};

BraintreeHostedForm.prototype.addFormHook = function (errorCallback) {
  var self = this;
  var shouldSubmit = false;

  function submit(payload) {
    shouldSubmit = true;

    $("#payment_method_nonce", self.hostedFields).val(payload.nonce);
    self.paymentForm.submit();
  }

  return function(hostedFields) {
    self.paymentForm.on("submit", function(e) {
      if (self.hostedFields.is(":visible") && !shouldSubmit) {
        e.preventDefault();

        hostedFields.tokenize(function(err, payload) {
          if (err) {
            errorCallback(err);
          } else {
            submit(payload);
          }
        });
      }
    });
  };
};
