//= require solidus_paypal_braintree/frontend

$(function() {
  /* This provides a default error handler for Braintree. Since we prevent
   * submission if tokenization fails, we need to manually re-enable the
   * submit button. */
  function braintreeError (err) {
    SolidusPaypalBraintree.config.braintreeErrorHandle(err);
    enableSubmit();
  }

  function enableSubmit() {
    /* If we're using jquery-ujs on the frontend, it will automatically disable
     * the submit button, but do so in a setTimeout here:
     * https://github.com/rails/jquery-rails/blob/master/vendor/assets/javascripts/jquery_ujs.js#L517
     * The only way we can re-enable it is by delaying longer than that timeout
     * or stopping propagation so their submit handler doesn't run. */
    if ($.rails && typeof $.rails.enableFormElement !== 'undefined') {
      setTimeout(function () {
        $.rails.enableFormElement($submitButton);
        $submitButton.attr("disabled", false).removeClass("disabled").addClass("primary");
      }, 100);
    } else if (typeof Rails !== 'undefined' && typeof Rails.enableElement !== 'undefined') {
      /* Indicates that we have rails-ujs instead of jquery-ujs. Rails-ujs was added to rails
       * core in Rails 5.1.0 */
      setTimeout(function () {
        Rails.enableElement($submitButton[0]);
        $submitButton.attr("disabled", false).removeClass("disabled").addClass("primary");
      }, 100);
    } else {
      $submitButton.attr("disabled", false).removeClass("disabled").addClass("primary");
    }
  }

  function disableSubmit() {
    $submitButton.attr("disabled", true).removeClass("primary").addClass("disabled");
  }

  function addFormHook(braintreeForm, hostedField) {
    $paymentForm.on("submit",function(event) {
      var $field = $(hostedField);

      if ($field.is(":visible") && !$field.data("submitting")) {
        var $nonce = $("#payment_method_nonce", $field);

        if ($nonce.length > 0 && $nonce.val() === "") {
          var client = braintreeForm._merchantConfigurationOptions._solidusClient;

          event.preventDefault();
          disableSubmit();

          braintreeForm.tokenize(function(error, payload) {
            if (error) {
              braintreeError(error);
              return;
            }

            $nonce.val(payload.nonce);

            if (!client.useThreeDSecure) {
              $paymentForm.submit();
              return;
            }

            threeDSecureOptions.nonce = payload.nonce;
            threeDSecureOptions.bin = payload.details.bin;
            threeDSecureOptions.onLookupComplete = function(data, next) {
              next();
            }
            client._threeDSecureInstance.verifyCard(threeDSecureOptions, function(error, response) {
              if (error === null && (!response.liabilityShiftPossible || response.liabilityShifted)) {
                $nonce.val(response.nonce);
                $paymentForm.submit();
              } else {
                $nonce.val('');
                braintreeError(error || { code: 'THREEDS_AUTHENTICATION_FAILED' });
              }
            });
          });
        }
      }
    });
  }

  var $paymentForm = $("#checkout_form_payment");
  var $hostedFields = $("[data-braintree-hosted-fields]");
  var $submitButton = $("input[type='submit']", $paymentForm);

  // If we're not using hosted fields, the form doesn't need to wait.
  if ($hostedFields.length > 0) {
    disableSubmit();

    var fieldPromises = $hostedFields.map(function(index, field) {
      var $this = $(this);
      var id = $this.data("id");

      var braintreeForm = new SolidusPaypalBraintree.createHostedForm(id);

      var formInitializationSuccess = function(formObject) {
        addFormHook(formObject, field);
      }

      return braintreeForm.initialize().then(formInitializationSuccess, braintreeError);
    });

    $.when.apply($, fieldPromises).done(enableSubmit);
  }

  var $paypalButton = $("#paypal-button");
  if ($paypalButton.length > 0) {
    var button = new SolidusPaypalBraintree.createPaypalButton($paypalButton[0], paypalOptions, (typeof options === 'undefined') ? {} : options);
    button.initialize();
  }

  var $applePayButton = $('#apple-pay-button');
  if ($applePayButton.length > 0) {
    var button = new SolidusPaypalBraintree.createApplePayButton($applePayButton[0], applePayOptions);
    button.initialize();
  }
});
