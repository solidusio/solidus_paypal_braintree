//= require solidus_paypal_braintree/constants
//= require solidus_paypal_braintree/hosted_form

$(function() {
  var $paymentForm = $("#new_payment"),
      $hostedFields = $("[data-braintree-hosted-fields]"),
      hostedFieldsInstance = null;

  function onError (err) {
    var msg = err.name + ": " + err.message;
    show_flash("error", msg);
  }

  function showForm(id) {
    $("#card_form" + id).show();
  }

  function hideForm(id) {
    $("#card_form" + id).hide();
  }

  function initFields($container, id) {
    function setHostedFieldsInstance(instance) {
      hostedFieldsInstance = instance;
      return instance;
    }

    if (hostedFieldsInstance === null) {
      braintreeForm = new SolidusPaypalBraintree.HostedForm($paymentForm, $container, id);
      braintreeForm.initializeHostedFields().
        then(setHostedFieldsInstance).
        then(braintreeForm.addFormHook(onError)).
        fail(onError);
    }
  }

  // exit early if we're not looking at the New Payment form, or if no
  // SolidusPaypalBraintree payment methods have been configured.
  if (!$paymentForm.length || !$hostedFields.length) { return; }

  $.when(
    $.getScript("https://js.braintreegateway.com/web/3.9.0/js/client.min.js"),
    $.getScript("https://js.braintreegateway.com/web/3.9.0/js/hosted-fields.min.js")
  ).done(function() {
    $hostedFields.each(function() {
      var $this = $(this),
          $radios = $("[name=card]", $this),
          id = $this.data("payment-method-id");

      // If we have previous cards, init fields on change of radio button
      if ($radios.length) {
        $radios.on("change", function() {
          if ($(this).val() == 'new') {
            showForm(id);
            initFields($this, id);
          } else {
            hideForm(id);
          }
        });
      } else {
        // If we don't have previous cards, init fields immediately
        initFields($this, id);
        showForm(id);
      }
    });
  });
});
