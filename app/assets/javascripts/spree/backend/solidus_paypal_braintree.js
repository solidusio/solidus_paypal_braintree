//= require vendor/braintree/client.js
//= require vendor/braintree/hosted_fields.js

$(function() {
  var $paymentForm = $("#new_payment"),
      $hostedFields = $("[data-braintree-hosted-fields]");

  // exit early if we're not looking at the New Payment form, or if no
  // SolidusPaypalBraintree payment methods have been configured.
  if (!$paymentForm.length || !$hostedFields.length) { return; }

  function promisify(fn, args, self) {
    var d = $.Deferred();

    fn.apply(self || this, (args || []).concat(function (err, data) {
      err && d.reject(err);
      d.resolve(data);
    }));

    return d.promise();
  }

  function getToken(paymentMethodId, callback) {
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
  }

  function createClient(token) {
    var opts = { authorization: token };
    return promisify(braintree.client.create, [opts]);
  }

  function createHostedFields(id) {
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

      return promisify(braintree.hostedFields.create, [opts]);
    }
  }

  $hostedFields.each(function() {
    var $this = $(this),
        $new = $("[name=card]", $this);

    var id = $this.data("id");

    var hostedFieldsInstance;

    $new.on("change", function() {
      var isNew = $(this).val() === "new";

      function onError(err) {
        var msg = err.name + ": " + err.message;
        show_flash("error", msg);
        console.error(err);
      }

      function setHostedFieldsInstance(instance) {
        hostedFieldsInstance = instance;
      }

      if (isNew && hostedFieldsInstance == null) {
        getToken(id).
          then(createClient).
          then(createHostedFields(id)).
          then(setHostedFieldsInstance).
          catch(onError)
      }
    });
  });
});
