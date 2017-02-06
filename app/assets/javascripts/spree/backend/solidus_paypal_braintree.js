//= require spree/braintree_hosted_form.js

$(function() {
  var $paymentForm = $("#new_payment"),
      $hostedFields = $("[data-braintree-hosted-fields]");

  function onError (err) {
    var msg = err.name + ": " + err.message;
    show_flash("error", msg);
    console.error(err);
  }

  // exit early if we're not looking at the New Payment form, or if no
  // SolidusPaypalBraintree payment methods have been configured.
  if (!$paymentForm.length || !$hostedFields.length) { return; }

  $hostedFields.each(function() {
    var $this = $(this),
        $new = $("[name=card]", $this);

    var id = $this.data("id");

    var hostedFieldsInstance;

    $new.on("change", function() {
      var isNew = $(this).val() === "new";

      function setHostedFieldsInstance(instance) {
        hostedFieldsInstance = instance;
        return instance;
      }

      if (isNew && hostedFieldsInstance == null) {
        braintreeForm = new BraintreeHostedForm($paymentForm, $this, id);
        braintreeForm.initializeHostedFields().
          then(setHostedFieldsInstance).
          then(braintreeForm.addFormHook(onError)).
          fail(onError)
      }
    });
  });
});
