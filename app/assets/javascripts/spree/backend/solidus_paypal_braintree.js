//= require spree/braintree_hosted_fields.js

$(function() {
  var $paymentForm = $("#new_payment"),
      $hostedFields = $("[data-braintree-hosted-fields]");

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
        BraintreeHostedFields.getToken(id).
          then(BraintreeHostedFields.createClient).
          then(BraintreeHostedFields.createHostedFields(id)).
          then(setHostedFieldsInstance).
          then(BraintreeHostedFields.addFormHook($this, $paymentForm)).
          fail(BraintreeHostedFields.onError)
      }
    });
  });
});
