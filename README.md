SolidusPaypalBraintree
======================

[![Build Status](https://travis-ci.org/solidusio/solidus_paypal_braintree.svg?branch=master)](https://travis-ci.org/solidusio/solidus_paypal_braintree)

`solidus_paypal_braintree` is an extension that adds support for using [Braintree](https://www.braintreepayments.com) as a payment source in your [Solidus](https://solidus.io/) store. It supports Apple Pay, PayPal, and credit card transactions.

Installation
------------

Add solidus_paypal_braintree to your Gemfile:

```ruby
gem 'solidus_paypal_braintree', github: 'solidusio/solidus_paypal_braintree', branch: :master
```

Bundle your dependencies and run the installation generator:

```shell
bundle
bundle exec rails g solidus_paypal_braintree:install
```

## Basic Setup

### Retrieve Braintree account details
You'll need the following account details:
- `Merchant ID`
- `Public key`
- `Private key`

These values can be obtained by logging in to your Braintree account, going
to `Account -> My User` and clicking `View Authorizations` in the **API Keys,
Tokenization Keys, Encryption Keys** section.

### Create a new payment method
1. Visit `/admin/payment_methods/new`.
2. Set `provider` to SolidusPaypalBraintree::Gateway
3. Enter the three required preferences: `merchant_id`, `public_key`, `private_key`. Other optional preferences are discussed below.
4. Click `Update` to save

Alternatively, create a payment method from the Rails console with:
```ruby
SolidusPaypalBraintree::Gateway.new(
  name: "Braintree",
  preferences: {
    public_key:  '[your public key]',
    private_key: '[your private key]',
    merchant_id: '[your merchant ID]'
  }
).save
```

### Configure payment types
Your payment method can accept payments in three ways: through Paypal, through ApplePay, or with credit card details entered directly by the customer. By default all are disabled for all your site's stores.
1. Visit /solidus_paypal_braintree/configurations/list
2. Check the payment types you'd like to accept. If your site has multiple stores, there'll be a set of checkboxes for each.
3. Click `Save changes` to save

Or from the console:
```ruby
Spree::Store.all.each do |store|
  store.create_braintree_configuration(
    credit_card: true,
    paypal: true,
    apple_pay: true
  )
end
```

3. If your site uses an unmodified `solidus_frontend`, it should now be ready to take credit card payments (if you've enabled that payment type). Paypal and ApplePay require some further configuration, discussed below.

Apple Pay
---------

### Setup
Braintree has some [excellent documentation](https://developers.braintreepayments.com/guides/apple-pay/configuration/javascript/v3) on what you'll need to do to get Apple Pay up and running.

In order to make everything a little simpler, this extension includes some client-side code to get you started. Specifically, it provides some wrappers to help with the initialization of an Apple Pay session. The following is a relatively bare-bones implementation:
```javascript
var applePayButton = document.getElementById('your-apple-pay-button');
window.SolidusPaypalBraintree.fetchToken(function(clientToken) {
  window.SolidusPaypalBraintree.initialize(clientToken, function(braintreeClient) {
    window.SolidusPaypalBraintree.setupApplePay(braintreeClient, "YOUR-MERCHANT-ID", funtion(applePayInstance) {
      applePayButton.addEventListener('click', function() { beginApplePayCheckout(applePayInstance) });
    }
  }
}

beginApplePayCheckout = function(applePayInstance) {
  window.SolidusPaypalBraintree.initializeApplePaySession({
    applePayInstance: applePayInstance,
    storeName: 'Your Store Name',
    currentUserEmail: Spree.current_email,
    paymentMethodId: Spree.braintreePaymentMethodId,
  }, (session) => {
    // Add in your logic for onshippingcontactselected and onshippingmethodselected.
  }
};
```

For additional information checkout the [Apple's documentation](https://developer.apple.com/reference/applepayjs/) and [Braintree's documentation](https://developers.braintreepayments.com/guides/apple-pay/client-side/javascript/v3).

### Development
Developing with Apple Pay has a few gotchas. First and foremost, you'll need to ensure you have access to a device running iOS 10+. (I've heard there's also been progress on adding support to the Simulator.)

Next, you'll need an Apple Pay sandbox account. You can check out Apple's [documentation](https://developer.apple.com/support/apple-pay-sandbox/) for additional help in performing this step.

Finally, Apple Pay requires the site to be served via HTTPS. I recommend setting up a proxy server to help solve this. There are [lots of guides](https://www.google.ca/search?q=nginx+reverse+proxy+ssl+localhost) on how this can be achieved.

PayPal
------

A default checkout view is provided that will display PayPal as a payment option.
It will only be displayed if the `SolidusPaypalBraintree::Gateway` payment
method is configured to display on the frontend and PayPal is enabled in the
store's configuration.

The checkout view
[initializes the PayPal button](/lib/views/frontend/spree/checkout/payment/_paypal_braintree.html.erb)
using the
[vault flow](https://developers.braintreepayments.com/guides/paypal/overview/javascript/v3),
which allows the source to be reused.

If you are creating your own checkout view or would like to customize the
[options that get passed to tokenize](https://braintree.github.io/braintree-web/3.6.3/PayPal.html#tokenize)
, you can initialize your own using the `PaypalButton` JS object:

```javascript
var button = new PaypalButton(document.querySelector("#your-button-id"));

button.initialize({
  // your configuration options here
});
```

After successful tokenization, a callback function is invoked that submits the
transaction via AJAX and advances the order to confirm. It is possible to provide
your own callback function to customize the behaviour after tokenize as follows:

```javascript
var button = new PaypalButton(document.querySelector("#your-button-id"));

button.setTokenizeCallback(your-callback);
```

## Optional configuration

### Accepting multiple currencies
The payment method also provides an optional preference `merchant_currency_map`.
This preference allows users to provide different Merchant Account Ids for
different currencies. If you only plan to accept payment in one currency, the
defaut Merchant Account Id will be used and you can omit this option.
An example of setting this preference can be found
[here](https://github.com/solidusio/solidus_paypal_braintree/blob/master/spec/spec_helper.rb#L70-L72).

### Default store configuration
The migrations for this gem will add a default configuration to all stores that
has each payment type disabled. It also adds a `before_create` callback to
`Spree::Store` that builds a default configuration. You can customize the
default configuration that gets created by overriding the private
`build_default_configuration` method on `Spree::Store`.

Testing
-------

First bundle your dependencies, then run `rake`. `rake` will default to building the dummy app if it does not exist, then it will run specs, and [Rubocop](https://github.com/bbatsov/rubocop) static code analysis. The dummy app can be regenerated by using `rake test_app`.

```shell
bundle
bundle exec rake
```

When testing your applications integration with this extension you may use it's factories.
Simply add this require statement to your spec_helper:

```ruby
require 'solidus_paypal_braintree/factories'
```

Copyright (c) 2016 Stembolt, released under the New BSD License
