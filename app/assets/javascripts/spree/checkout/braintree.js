//= require spree/braintree_hosted_form

$(function() {
  /* This provides a default error handler for Braintree. Since we prevent
   * submission if tokenization fails, we need to manually re-enable the
   * submit button. */
  function braintreeError (err) {
    alert(err.name + ": " + err.message);

    $submitButton = $("input[type='submit']", $paymentForm);
    /* If we're using jquery-ujs on the frontend, it will automatically disable
     * the submit button, but do so in a setTimeout here:
     * https://github.com/rails/jquery-rails/blob/master/vendor/assets/javascripts/jquery_ujs.js#L517
     * The only way we can re-enable it is by delaying longer than that timeout
     * or stopping propagation so their submit handler doesn't run. */
    if ($.rails) {
      setTimeout(function () {
        $.rails.enableFormElement($submitButton);
      }, 100);
    }
    /* This reverses Spree.disableSaveOnClick() */
    $submitButton.attr("disabled", false).addClass("primary").removeClass("disabled");
  }

  var $paymentForm = $("#checkout_form_payment"),
  $hostedFields = $("[data-braintree-hosted-fields]");

  $.when(
    $.getScript("https://js.braintreegateway.com/web/3.9.0/js/client.min.js"),
    $.getScript("https://js.braintreegateway.com/web/3.9.0/js/hosted-fields.min.js")
  ).done(function() {
    $hostedFields.each(function() {
      var $this = $(this);
      var id = $this.data("id");

      var braintreeForm = new BraintreeHostedForm($paymentForm, $this, id);
      braintreeForm.initializeHostedFields().
        then(braintreeForm.addFormHook(braintreeError)).
        fail(braintreeError);
    });
  });
});
