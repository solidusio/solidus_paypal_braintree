//= require solidus_braintree/constants
/**
 * Constructor for Venmo button object
 * @constructor
 * @param {object} element - The DOM element of your Venmo button
 */
SolidusBraintree.VenmoButton = function(element, venmoOptions) {
  this._element = element;
  this._client = null;
  this._venmoOptions = venmoOptions || {};

  if(!this._element) {
    throw new Error("Element for the Venmo button must be present on the page");
  }
};

/**
 * Creates the Venmo session using the provided options and enables the button
 *
 * @param {object} options - The options passed to tokenize when constructing
 *                           the Venmo instance
 *
 * See {@link https://braintree.github.io/braintree-web/3.84.0/module-braintree-web_venmo.html#.create}
 */
SolidusBraintree.VenmoButton.prototype.initialize = function() {
  this._client = new SolidusBraintree.createClient({
    useVenmo: true,
    newBrowserTabSupported: this._venmoOptions.newBrowserTabSupported,
    flow: this._venmoOptions.flow
  });

  return this._client.initialize().then(this.initializeCallback.bind(this));
};

SolidusBraintree.VenmoButton.prototype.initializeCallback = function() {
  this._venmoInstance = this._client.getVenmoInstance();

  this._element.classList.add('visible');

  // Check if tokenization results already exist. This occurs when your
  // checkout page is relaunched in a new tab.
  if (!this._venmoOptions.newBrowserTabSupported && this._venmoInstance.hasTokenizationResult()) {
    this.tokenize();
  }

  this._element.addEventListener('click', function(event) {
    event.preventDefault();
    this._element.disabled = true;
    this.initializeVenmoSession();
  }.bind(this), false);
};

SolidusBraintree.VenmoButton.prototype.initializeVenmoSession = function() {
  this.tokenize();
};

SolidusBraintree.VenmoButton.prototype.tokenize = function() {
  var venmoButton = this._element;
  this._venmoInstance.tokenize().then(handleVenmoSuccess).catch(handleVenmoError).then(function () {
    venmoButton.removeAttribute('disabled');
  });
};

function handleVenmoSuccess(payload) {
  var $paymentForm = $("#checkout_form_payment");
  var $nonceField = $("#venmo_payment_method_nonce", $paymentForm);

  // Disable hostedFields' and enable Venmo's inputs as they use the same fields.
  // Otherwise, they will clash. (Disabled inputs are not used on form submission)
  $('.hosted-fields input').each(function(_index, input) {
    input.disabled = true;
  });
  $('.venmo-fields input').each(function(_index, input) {
    input.removeAttribute('disabled');
  });

  // remove hostedFields submit listener, otherwise empty credit card errors occur
  $paymentForm.off('submit');

  $nonceField.val(payload.nonce);
  $paymentForm.submit();
}

function handleVenmoError(error) {
  SolidusBraintree.config.braintreeErrorHandle(error);
}
