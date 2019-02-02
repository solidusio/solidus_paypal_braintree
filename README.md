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
Payment methods can accept preferences either directly entered in admin, or from a static source in code. For most projects we recommend using a static source, so that sensitive account credentials are not stored in the database.

1. Set static preferences in an initializer
  ```ruby
  # config/initializers/spree.rb
  Spree::Config.configure do |config|
    config.static_model_preferences.add(
      SolidusPaypalBraintree::Gateway,
      'braintree_credentials', {
        environment: Rails.env.production? ? 'production' : 'sandbox',
        merchant_id: ENV['BRAINTREE_MERCHANT_ID'],
        public_key: ENV['BRAINTREE_PUBLIC_KEY'],
        private_key: ENV['BRAINTREE_PRIVATE_KEY'],
        paypal_flow: 'vault', # 'checkout' is accepted too
      }
    )
  end
  ```
  Other optional preferences are discussed below.

2. Visit `/admin/payment_methods/new`

3. Set `provider` to SolidusPaypalBraintree::Gateway

4. Click "Save"

5. Choose `braintree_credentials` from the `Preference Source` select

6. Click `Update` to save

Alternatively, create a payment method from the Rails console with:
```ruby
SolidusPaypalBraintree::Gateway.new(
  name: "Braintree",
  preference_source: "braintree_credentials"
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

4. If your site uses an unmodified `solidus_frontend`, it should now be ready to take payments. See below for more information on configuring Paypal and ApplePay.

5. Typical Solidus sites will have customized frontend code, and may require some additional work. Use `lib/views/frontend/spree/checkout/payment/_paypal_braintree.html.erb` and `app/assets/javascripts/solidus_paypal_braintree/checkout.js` as models.

## Apple Pay
### Developing with Apple Pay
You'll need the following:
- A device running iOS 10+.
- An Apple Pay sandbox account. You can check out Apple's [documentation](https://developer.apple.com/support/apple-pay-sandbox/) for additional help in performing this step.
- A site served via HTTPS. To set this up for development we recommend setting up a reverse proxy server. There are [lots of guides](https://www.google.ca/search?q=nginx+reverse+proxy+ssl+localhost) on how this can be achieved.
- A Braintree sandbox account with Apple Pay enabled (`Settings>Processing`) and configured (`Settings>Processing>Options`) with your Apple Merchant ID and the HTTPS domain for your site.
- A sandbox user logged in to your device, with a [test card](https://developer.apple.com/support/apple-pay-sandbox/) in its Wallet

### Enabling Apple Pay for custom frontends
The following is a relatively bare-bones implementation to enable Apple Pay on the frontend:

```html
<% if current_store.braintree_configuration.apple_pay? %>
  <script src="https://js.braintreegateway.com/web/3.22.1/js/apple-pay.min.js"></script>

  <button id="apple-pay-button" class="apple-pay-button"></button>

  <script>
    var applePayButtonElement = document.getElementById('apple-pay-button');
    var applePayOptions = {
      paymentMethodId: <%= id %>,
      storeName: "<%= current_store.name %>",
      orderEmail: "<%= current_order.email %>",
      amount: "<%= current_order.total %>",
      shippingContact: {
        emailAddress: '<%= current_order.email %>',
        familyName: '<%= address.firstname %>',
        givenName: '<%= address.lastname %>',
        phoneNumber: '<%= address.phone %>',
        addressLines: ['<%= address.address1 %>','<%= address.address2 %>'],
        locality: '<%= address.city %>',
        administrativeArea: '<%= address.state.name %>',
        postalCode: '<%= address.zipcode %>',
        country: '<%= address.country.name %>',
        countryCode: '<%= address.country.iso %>'
      }
    };
    var button = new SolidusPaypalBraintree.createApplePayButton(applePayButtonElement, applePayOptions);
    button.initialize();
  </script>
<% end %>
```

### Further Apple Pay information
Braintree has some [excellent documentation](https://developers.braintreepayments.com/guides/apple-pay/configuration/javascript/v3) on what you'll need to do to get Apple Pay up and running.

For additional information check out [Apple's documentation](https://developer.apple.com/reference/applepayjs/) and [Braintree's documentation](https://developers.braintreepayments.com/guides/apple-pay/client-side/javascript/v3).

PayPal
------

A default checkout view is provided that will display PayPal as a payment option.
It will only be displayed if the `SolidusPaypalBraintree::Gateway` payment
method is configured to display on the frontend and PayPal is enabled in the
store's configuration.

The checkout view
[initializes the PayPal button](/lib/views/frontend/spree/checkout/payment/_paypal_braintree.html.erb)
using the
[Vault flow](https://developers.braintreepayments.com/guides/paypal/overview/javascript/v3),
which allows the source to be reused. If you want, you can use [Checkout with PayPal](https://developers.braintreepayments.com/guides/paypal/checkout-with-paypal/javascript/v3)
instead, which doesn't allow you to reuse sources but allows your customers to pay with their PayPal
balance (see setup instructions).

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

### Express checkout from the cart

A PayPal button can also be included on the cart view to enable express checkouts:
```ruby
render "spree/shared/paypal_cart_button"
```

#### PayPal configuration

If your store requires the [phone number into user addresses](https://github.com/solidusio/solidus/blob/859143f3f061de79cc1b385234599422b8ae8e21/core/app/models/spree/address.rb#L151-L153)
you'll need to configure PayPal to return the phone back when it returns the
address used by the user:

1. Log into your PayPal account
2. Go to Profile -> My Selling Tools -> Website preferences
3. Set Contact Telephone to `On (Required Field)` or `On (Optional Field)`

Using the option `Off` will not make the address valid and will raise a
validation error.

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
