//= require solidus_paypal_braintree/constants
//= require solidus_paypal_braintree/hosted_form

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
        braintreeForm = new SolidusPaypalBraintree.createHostedForm(id);
        braintreeForm.initialize().
          then(setHostedFieldsInstance).
          then(braintreeForm.addFormHook(onError)).
          fail(onError)
      }
    });
  });
});
