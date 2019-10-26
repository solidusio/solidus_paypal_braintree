/**
 * Braintree client interface
 * @external "braintree.Client"
 * @see {@link https://braintree.github.io/braintree-web/current/Client.html|Braintree Client Docs}
**/

/**
 * Braintree paypal interface
 * @external "braintree.PayPal"
 * @see {@link https://braintree.github.io/braintree-web/current/PayPal.html|Braintree Paypal Docs}
**/

/**
 * Braintree paypal interface
 * @external "braintree.ApplePay"
 * @see {@link https://braintree.github.io/braintree-web/current/ApplePay.html|Braintree Apple Pay Docs}
**/

/**
 * Braintree dataCollector interface
 * @external "braintree.DataCollector"
 * @see {@link https://braintree.github.io/braintree-web/current/DataCollector.html|Braintree DataCollector Docs}
**/

/**
 * jQuery.Deferred interface
 *
 * We use this for our promises because ES6 promises are non standard, and because jquery 1/2
 * promises do not play nicely with them.
 * @external "jQuery.Deferred"
 * @see {@link https://api.jquery.com/category/deferred-object/|jQuery Deferred Documentation}
**/

/**
 * Represents a wrapper around the braintree js library.
 *
 * This class is responsible for fetching tokens from a solidus store and using them
 * to manage a braintree client. It takes a number of options as capabilities for the client
 * depending on if you want to use use the data collector or paypal.
 *
 * We use this class mostly to hide the token operations for users.
 *
 * After creating the class, a call should be made to initialize before using it.
 * @see initialize
 *
 * @constructor
 * @param {Object} config Initalization options for the client
 * @param {Boolean} config.useDataCollector Use data collector capabilities for the braintree client
 * @param {Boolean} config.usePaypal Use Paypal capabilities for the braintree client
 * @param {requestCallback} config.readyCallback A callback to be invoked when the client is ready to go.
 * @param {Number} config.paymentMethodId A number indicating a specific payment method to be preferrred.
 *
**/
SolidusPaypalBraintree.Client = function(config) {
  this.paymentMethodId = config.paymentMethodId;
  this.readyCallback = config.readyCallback;
  this.useDataCollector = config.useDataCollector;
  this.usePaypal = config.usePaypal;
  this.useApplepay = config.useApplepay;
  this.useThreeDSecure = config.useThreeDSecure;

  this._braintreeInstance = null;
  this._dataCollectorInstance = null;
  this._paypalInstance = null;
  this._threeDSecureInstance = null;
};

/**
 * Fetches a client token from the backend and initializes the braintree client.
 * @returns {external:"jQuery.Deferred"} Promise to be invoked after initialization is complete
**/
SolidusPaypalBraintree.Client.prototype.initialize = function() {
  var initializationPromise = this._fetchToken().
    then(this._createBraintreeInstance.bind(this));

  if (this.useDataCollector) {
    initializationPromise = initializationPromise.then(this._createDataCollector.bind(this));
  }

  if (this.usePaypal) {
    initializationPromise = initializationPromise.then(this._createPaypal.bind(this));
  }

  if (this.useApplepay) {
    initializationPromise = initializationPromise.then(this._createApplepay.bind(this));
  }

  if (this.useThreeDSecure) {
    initializationPromise = initializationPromise.then(this._createThreeDSecure.bind(this));
  }

  return initializationPromise.then(this._invokeReadyCallback.bind(this));
};

/**
 * Returns the braintree client instance
 * @returns {external:"braintree.Client"} The braintree client that was initialized by this class
**/
SolidusPaypalBraintree.Client.prototype.getBraintreeInstance = function() {
  return this._braintreeInstance;
};

/**
 * Returns the braintree paypal instance
 * @returns {external:"braintree.PayPal"} The braintree paypal that was initialized by this class
**/
SolidusPaypalBraintree.Client.prototype.getPaypalInstance = function() {
  return this._paypalInstance;
};

/**
 * Returns the braintree Apple Pay instance
 * @returns {external:"braintree.ApplePay"} The Braintree Apple Pay that was initialized by this class
**/
SolidusPaypalBraintree.Client.prototype.getApplepayInstance = function() {
  return this._applepayInstance;
};

/**
 * Returns the braintree dataCollector instance
 * @returns {external:"braintree.DataCollector"} The braintree dataCollector that was initialized by this class
**/
SolidusPaypalBraintree.Client.prototype.getDataCollectorInstance = function() {
  return this._dataCollectorInstance;
};


SolidusPaypalBraintree.Client.prototype._fetchToken = function() {
  var payload = {
    dataType: 'json',
    type: 'POST',
    url: SolidusPaypalBraintree.config.paths.clientTokens,
    error: function(xhr) {
      console.error("Error fetching braintree token");
    }
  };

  if (this.paymentMethodId) {
    payload.data = {
      payment_method_id: this.paymentMethodId
    };
  }

  return Spree.ajax(payload);
};

SolidusPaypalBraintree.Client.prototype._createBraintreeInstance = function(tokenResponse) {
  this.paymentMethodId = tokenResponse.payment_method_id;

  return SolidusPaypalBraintree.PromiseShim.convertBraintreePromise(braintree.client.create, [{
    authorization: tokenResponse.client_token
  }]).then(function (clientInstance) {
    this._braintreeInstance = clientInstance;
    return clientInstance;
  }.bind(this));
};

SolidusPaypalBraintree.Client.prototype._invokeReadyCallback = function() {
  if(this.readyCallback) {
    this.readyCallback(this._braintreeInstance);
  }

  return this;
};

SolidusPaypalBraintree.Client.prototype._createDataCollector = function() {
  return SolidusPaypalBraintree.PromiseShim.convertBraintreePromise(braintree.dataCollector.create, [{
    client: this._braintreeInstance,
    paypal: !!this.usePaypal
  }]).then(function (dataCollectorInstance) {
    this._dataCollectorInstance = dataCollectorInstance;
    return dataCollectorInstance;
  }.bind(this));
};

SolidusPaypalBraintree.Client.prototype._createPaypal = function() {
  return SolidusPaypalBraintree.PromiseShim.convertBraintreePromise(braintree.paypalCheckout.create, [{
    client: this._braintreeInstance
  }]).then(function (paypalInstance) {
    this._paypalInstance = paypalInstance;
    return paypalInstance;
  }.bind(this), function(error) {
    console.error(error.name + ':', error.message);
  });
};

SolidusPaypalBraintree.Client.prototype._createApplepay = function() {
  return SolidusPaypalBraintree.PromiseShim.convertBraintreePromise(braintree.applePay.create, [{
    client: this._braintreeInstance
  }]).then(function (applePayInstance) {
    this._applepayInstance = applePayInstance;
    return applePayInstance;
  }.bind(this));
};

SolidusPaypalBraintree.Client.prototype._createThreeDSecure = function() {
  return SolidusPaypalBraintree.PromiseShim.convertBraintreePromise(braintree.threeDSecure.create, [{
    client: this._braintreeInstance,
    version: 2
  }]).then(function (threeDSecureInstance) {
    this._threeDSecureInstance = threeDSecureInstance;
  }.bind(this), function(error) {
    console.log(error);
  });
};
