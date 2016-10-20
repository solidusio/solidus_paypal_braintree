//= require vendor/braintree/client.js
//= require vendor/braintree/hosted_fields.js

window.BraintreeHostedFields = {
  promisify: function (fn, args, self) {
    var d = $.Deferred();

    fn.apply(self || this, (args || []).concat(function (err, data) {
      err && d.reject(err);
      d.resolve(data);
    }));

    return d.promise();
  },

  onError: function (err) {
    var msg = err.name + ": " + err.message;
    show_flash("error", msg);
    console.error(err);
  },

  getToken: function (paymentMethodId, callback) {
    var opts = {
      url: "/solidus_paypal_braintree/client_token",
      method: "POST",
      data: {
        payment_method_id: paymentMethodId
      },
    };

    function onSuccess(data) {
      return data.client_token;
    }

    return Spree.ajax(opts).then(onSuccess);
  },

  createClient: function (token) {
    var opts = { authorization: token };
    return BraintreeHostedFields.promisify(braintree.client.create, [opts]);
  },

  createHostedFields: function (id) {
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

      return BraintreeHostedFields.promisify(braintree.hostedFields.create, [opts]);
    }
  },

  addFormHook: function ($fields, $paymentForm) {
    var shouldSubmit = false;

    function submit(payload) {
      shouldSubmit = true;

      $("#payment_method_nonce", $fields).val(payload.nonce);
      $paymentForm.submit();
    }

    return function(hostedFields) {
      $paymentForm.on("submit", function(e) {
        if ($fields.is(":visible") && !shouldSubmit) {
          e.preventDefault()

          hostedFields.tokenize(function(err, payload) {
            if (err) {
              onError(err);
            } else {
              submit(payload);
            }
          })
        }
      });
    }
  }
}
