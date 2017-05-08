SolidusPaypalBraintree = {
  APPLY_PAY_API_VERSION: 1,

  // Override to provide your own error messages.
  braintreeErrorHandle: function(braintreeError) {
    var $contentContainer = $("#content");
    var $flash = $("<div class='flash error'>" + braintreeError.name + ": " + braintreeError.message + "</div>");
    $contentContainer.prepend($flash);

    $flash.show().delay(5000).fadeOut(500);
  }
};
