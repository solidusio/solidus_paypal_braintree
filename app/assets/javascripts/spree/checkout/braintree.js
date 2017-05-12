//= require spree/braintree_hosted_form

$(function() {
  /* This provides a default error handler for Braintree. Since we prevent
   * submission if tokenization fails, we need to manually re-enable the
   * submit button. */
  function braintreeError (err) {
    SolidusPaypalBraintree.braintreeErrorHandle(err);
    enableSubmit();
  }

  function enableSubmit() {
    /* If we're using jquery-ujs on the frontend, it will automatically disable
     * the submit button, but do so in a setTimeout here:
     * https://github.com/rails/jquery-rails/blob/master/vendor/assets/javascripts/jquery_ujs.js#L517
     * The only way we can re-enable it is by delaying longer than that timeout
     * or stopping propagation so their submit handler doesn't run. */
    if ($.rails) {
      setTimeout(function () {
        $.rails.enableFormElement($submitButton);
        $submitButton.attr("disabled", false).removeClass("disabled").addClass("primary");
      }, 100);
    } else {
      $submitButton.attr("disabled", false).removeClass("disabled").addClass("primary");
    }
  }

  function disableSubmit() {
    $submitButton.attr("disabled", true).removeClass("primary").addClass("disabled");
  }

  var $paymentForm = $("#checkout_form_payment");
  var $hostedFields = $("[data-braintree-hosted-fields]");
  var $submitButton = $("input[type='submit']", $paymentForm);
  var $checkoutForm = $("#checkout_form_payment");

  // If we're not using hosted fields, the form doesn't need to wait.
  if ($hostedFields.length > 0) {
    disableSubmit();
  }

  $checkoutForm.submit(disableSubmit);

  $.when(
    $.getScript("https://js.braintreegateway.com/web/3.9.0/js/client.min.js"),
    $.getScript("https://js.braintreegateway.com/web/3.9.0/js/hosted-fields.min.js")
  ).done(function() {
    var fieldPromises = $hostedFields.map(function() {
      var $this = $(this);
      var id = $this.data("id");

      var braintreeForm = new BraintreeHostedForm($paymentForm, $this, id);
      return braintreeForm.initializeHostedFields().
        then(braintreeForm.addFormHook(braintreeError)).
        fail(braintreeError);
    });

    $.when.apply($, fieldPromises).done(enableSubmit);
  });
});
