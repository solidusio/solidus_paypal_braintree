# SolidusPaypalBraintree

⛔️ This extension is archived. ⛔️

It has been renamed and moved to [solidus_braintree](https://github.com/solidusio/solidus_braintree).

If you were using this project, you can follow the [instructions to upgrade to the new extension](https://github.com/solidusio/solidus_braintree/wiki/Upgrading-from-SolidusPaypalBraintree-To-SolidusBraintree).

<hr>
<br>

[![CircleCI](https://circleci.com/gh/solidusio/solidus_paypal_braintree.svg?style=shield)](https://circleci.com/gh/solidusio/solidus_paypal_braintree)
[![codecov](https://codecov.io/gh/solidusio/solidus_paypal_braintree/branch/master/graph/badge.svg)](https://codecov.io/gh/solidusio/solidus_paypal_braintree)

`solidus_paypal_braintree` is an extension that adds support for using [Braintree](https://www.braintreepayments.com) as a payment source in your [Solidus](https://solidus.io/) store. It supports Apple Pay, PayPal, and credit card transactions.

🚧 This extension is currently only compatible with the legacy `solidus_frontend` 🚧

## Installation

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
  Rails.application.config.to_prepare do
    Spree::Config.static_model_preferences.add(
      SolidusPaypalBraintree::Gateway,
      'braintree_credentials', {
        environment: Rails.env.production? ? 'production' : 'sandbox',
        merchant_id: ENV['BRAINTREE_MERCHANT_ID'],
        public_key: ENV['BRAINTREE_PUBLIC_KEY'],
        private_key: ENV['BRAINTREE_PRIVATE_KEY'],
        paypal_flow: 'vault', # 'checkout' is accepted too
        use_data_collector: true # Fingerprint the user's browser when using Paypal
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
Your payment method can accept payments in three ways: through Paypal, through ApplePay, or with credit card details entered directly by the customer. By default all are disabled for all your site's stores. Before proceeding to checkout, ensure you've created a Braintree configuration for your store:

1. Visit /solidus_paypal_braintree/configurations/list

2. Check the payment types you'd like to accept. If your site has multiple stores, there'll be a set of checkboxes for each.

3. Click `Save changes` to save

  Or from the console:
  ```ruby
  Spree::Store.all.each do |store|
    store.create_braintree_configuration(
      credit_card: true,
      paypal: true,
      apple_pay: true,
      venmo: true
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
  <script src="https://js.braintreegateway.com/web/3.84.0/js/apple-pay.min.js"></script>

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
        givenName: '<%= address.firstname %>',
        familyName: '<%= address.lastname %>',
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

## Venmo
There are two ways for users to use Venmo for payments:
1. Braintree's native Venmo integration, which supports vaulting of payment sources. [See more.](#Braintree's-Venmo)
2. Through the PayPal buttons when using checkout flow, therefore doesn't support vaulting. [See more.](#PayPal-financing-options)

### PayPal's Venmo financing option
To add Venmo for PayPal, [see here](#paypal-venmo)

### Braintree's Venmo
#### Note
- Only available as a financing option on the checkout page; Venmo currently does not support shipping callbacks so it cannot be on the cart page.
- Currently available to US merchants and buyers and there are also other prequisites.
  - https://developer.paypal.com/docs/business/checkout/pay-with-venmo/#eligibility
  - https://developer.paypal.com/braintree/articles/guides/payment-methods/venmo#availability

#### Integration:
1. Enable Venmo in your [Braintree account](https://developer.paypal.com/braintree/articles/guides/payment-methods/venmo#setup)
2. Enable Venmo in your [store's Braintree configuration](#configure-payment-types).
3. Ensure your Braintree API credentials are in the Braintree payment method.
4. Set your Braintree payment method's preference of `preferred_venmo_new_tab_support` to `false` if your store cannot handle Venmo returning a user to a new tab after payment. This may be because your website is a single-page applicaiton (SPA). On mobile, the user may be returned to the same store tab if their browser supports it, otherwise a new tab will be created (unless you have this preference as `false`).

By default your default Venmo business account will be used. If you want to use a non-default profile, override
the `SolidusPaypalBraintree::Gateway` `#venmo_business_profile_id` method with its id.

#### Testing
Test the following scenarios:
- Ensure the Venmo checkout button opens a modal with a QR code and is closeable.
- Do a full transaction
- Ensure that you can also save the payment source in the user wallet.
- Ensure the saved Venmo wallet payment source loads in the partial correctly.
- Ensure the saved Venmo payment source can be reused for another order.
- Test doing transactions on the admin
- Testing voiding and refunding Venmo transactions

You'll need the Venmo app in order to fully test the integration. However, if you are outside of the US, this is not an option. You can fake the tokenization by:
- Altering the `venmo_button.js` file to call the `handleVenmoSuccess` function instead of tokenizing; or
- Manually doing its steps:
  1. Update the #venmo_payment_method_nonce hidden input value to "fake-venmo-account-nonce".
  2. Remove the disabled attributes from the venmo-fields inputs.
  3. If you have hosted fields on the page (`credit_card` enabled in Braintree configuration), remove it's submit button listener:
    `$('#checkout_form_payment').off('submit');`

[More information](https://developer.paypal.com/braintree/articles/guides/payment-methods/venmo#availability)

#### Customization:
In your [store's Braintree configuration](#configure-payment-types), you can customize the Venmo checkout button's color and width.

Note, other images such as Venmo's full logo and shortened "V" logo are included in the assets.

Ensure that you follow [Venmo's guidelines](https://developer.paypal.com/braintree/docs/files/venmo-merchant-integration-guidelines.pdf) when making other style changes, otherwise failing to comply can lead to an interruption of your Venmo service.

## PayPal

A default checkout view is provided that will display PayPal as a payment option.
It will only be displayed if the `SolidusPaypalBraintree::Gateway` payment
method is configured to display on the frontend and PayPal is enabled in the
store's configuration.

You can find button configuration options in
`/solidus_paypal_braintree/configurations/list` if you want to change the color,
shape, layout, and a few other options. For more information check out
[PayPal's documentation](https://developer.paypal.com/docs/platforms/checkout/reference/style-guide/#layout).

Keep in mind that:
- `paypal_button_tagline` does not work when the `paypal_button_layout` is set to `vertical`, and will be ignored; and
- `paypal_button_layout` of `horizontal` limits financing options/buttons to 2, where as `vertical` is 4.
  Other available financing options after the limit will not be rendered in the PayPal's iframe DOM.

The checkout view
[initializes the PayPal button](/lib/views/frontend/spree/checkout/payment/_paypal_braintree.html.erb)
using the
[Vault flow](https://developers.braintreepayments.com/guides/paypal/overview/javascript/v3),
which allows the source to be reused. Please note that PayPal messaging is disabled with vault flow. If you want, you can use [Checkout with PayPal](https://developers.braintreepayments.com/guides/paypal/checkout-with-paypal/javascript/v3)
instead, which doesn't allow you to reuse sources but allows your customers to pay with their PayPal
balance and with PayPal financing options ([see setup instructions](#create-a-new-payment-method)). More information about other [financing options below](#paypal-financing-options).

If you are creating your own checkout view or would like to customize the
[options that get passed to tokenize](https://braintree.github.io/braintree-web/3.6.3/PayPal.html#tokenize)
, you can initialize your own using the `CreatePaypalButton` JS object:

```javascript
var paypalOptions = {
  // your configuration options here
}

var button = new SolidusPaypalBraintree.createPaypalButton(document.querySelector("#your-button-id"), paypalOptions);

button.initialize();
```

### Express checkout from the cart

A PayPal button can also be included on the cart view to enable express checkouts:
```ruby
render "spree/shared/paypal_cart_button"
```

### PayPal financing options
When using 'checkout' `paypal flow` and not 'vault'. Your customers can have different finance options such as
- paylater
- Venmo

#### PayPal Venmo
Venmo is currently available to US merchants and buyers. There are also other [prequisites](https://developer.paypal.com/docs/business/checkout/pay-with-venmo/#eligibility).

By default, the extension and Braintree will try to render a Venmo button to buyers when prequisites are met and you have enabled it in your Braintree account).

Set the SolidusPaypalBraintree `PaymentMethod` `enable_venmo_funding` preference to:
- `enabled`, available as a PayPal funding option (if other prequisites are met); or
- `disabled` (default).

Note, Venmo is currently only available as a financing option on the checkout page; Venmo currently does not support shipping callbacks so it cannot be on the cart page.

[_As Venmo is only available in the US, you may want to mock your location for testing_](#mocking-your-buyer-country)

### PayPal Financing Messaging

PayPal offers an [on-site messaging component](https://www.paypal.com/us/webapps/mpp/on-site-messaging) to notify the customer that there are financing options available. This component is included in both the cart and checkout partials, but is disabled by default. To enable this option, you'll need to use the `checkout` flow, and set the `paypal button messaging` option to `true` in your Braintree configuration.

You can also include this view partial to implement this messaging component anywhere - for instance, on the product page:
```ruby
render "spree/shared/paypal_messaging, options: {total: @product.price, placement: "product", currency: 'USD'}"
```

While we provide the messaging component on the payment buttons for cart and checkout, you're expected to move these to where they make the most sense for your frontend. PayPal recommends keeping the messaging directly below wherever the order or product total is located.

#### PayPal configuration

If your store requires the [phone number into user addresses](https://github.com/solidusio/solidus/blob/859143f3f061de79cc1b385234599422b8ae8e21/core/app/models/spree/address.rb#L151-L153)
you'll need to configure PayPal to return the phone back when it returns the
address used by the user:

1. Log into your PayPal account
2. Hover over the user in the Navbar to get the dropdown
3. Click on Account Settings
4. In the left panel under Products & Services, click Website Payments
5. Click Update for Website Preferences
6. Set Contact Telephone to `On (Required Field)` or `On (Optional Field)`

Using the option `Off` will not make the address valid and will raise a
validation error.

#### Disabling the data collector

For fraud prevention, PayPal recommends using a data collector to collect device
information, which we've included by default. You're able to turn off the PayPal
data collector on the payment method preferences if you desire. If you use
static preferences, add `use_data_collector: false` to your initializer.

## Optional configuration

### Accepting multiple currencies
The payment method also provides an optional preference `merchant_currency_map`.
This preference allows users to provide different Merchant Account Ids for
different currencies. If you only plan to accept payment in one currency, the
defaut Merchant Account Id will be used and you can omit this option.
An example of setting this preference can be found
[here](https://github.com/solidusio/solidus_paypal_braintree/blob/bf5fe0e154d38f7c498f1c54450bb4de7608ff04/spec/support/gateway_helpers.rb#L11-L13).

In addition to this, you can also specify different PayPal accounts for each
currency by using the `paypal_payee_email_map` preference. If you only want
to use one PayPal account for all currencies, then you can ignore this option.
You can find an example of setting this preference [here](https://github.com/solidusio/solidus_paypal_braintree/blob/bf5fe0e154d38f7c498f1c54450bb4de7608ff04/spec/support/gateway_helpers.rb#L14-L16).

### Default store configuration
The migrations for this gem will add a default configuration to all stores that
has each payment type disabled. It also adds a `before_create` callback to
`Spree::Store` that builds a default configuration. You can customize the
default configuration that gets created by overriding the private
`build_default_configuration` method on `Spree::Store`.

### Hosted Fields Styling
You can style the Braintree credit card fields by using the `credit_card_fields_style` preference on the payment method. The `credit_card_fields_style` will be passed to the `style` key when initializing the credit card fields. You can find more information about styling hosted fields can be found [here.](https://developers.braintreepayments.com/guides/hosted-fields/styling/javascript/v3)

You can also use the `placeholder_text` preference on the payment method to set the placeholder text you'd like to use for each of the hosted fields. You'll pass the field name in as the key, and the placeholder text you'd like to use as the value. For example:
```ruby
  { number: "Enter card number", cvv: "Enter CVV", expirationDate: "mm/yy" }
```

### 3D Secure

This gem supports [3D Secure 2](https://developers.braintreepayments.com/guides/3d-secure/overview),
which satisfies the [Strong Customer Authentication (SCA)](https://www.braintreepayments.com/blog/getting-up-to-speed-on-psd2-regulation-2/)
requirements introduced by PSD2.

3D Secure can be enabled from Solidus Admin -> Braintree (left-side menu) ->
tick _3D Secure_ checkbox.

Once enabled, you can use the following card numbers to test 3DS 2 on your
client side in sandbox:
https://developers.braintreepayments.com/guides/3d-secure/migration/javascript/v3#client-side-sandbox-testing.

## Testing

To run the specs it is required to set the Braintree test account data in these environment variables:
`BRAINTREE_PUBLIC_KEY`, `BRAINTREE_PRIVATE_KEY`, `BRAINTREE_MERCHANT_ID` and `BRAINTREE_PAYPAL_PAYEE_EMAIL`

First bundle your dependencies, then run `rake`. `rake` will default to building the dummy app if it does not exist, then it will run specs, and [Rubocop](https://github.com/bbatsov/rubocop) static code analysis. The dummy app can be regenerated by using `rake test_app`.

```shell
bundle
bundle exec rake
```

When testing your applications integration with this extension you may use it's factories.
Simply add this require statement to your spec_helper:

```ruby
require 'solidus_paypal_braintree/testing_support/factories'
```

## Development

### Mocking your buyer country
PayPal looks at the buyer's IP geolocation to determine what funding sources should be available to them. Because for example, Venmo is currently only available to US buyers. Because of this, you may want to pretend that you are from US so you can check if Venmo is correctly integrated for these customers. To do this, set the payment method's preference of `force_buyer_country` to "US". See more information about preferences above.

This preference has no effect on production.

### Running the sandbox

To run this extension in a sandboxed Solidus application, you can run `bin/sandbox`. The path for
the sandbox app is `./sandbox` and `bin/rails` will forward any Rails commands to
`sandbox/bin/rails`.

Here's an example:

```
$ bin/rails server
=> Booting Puma
=> Rails 7.0.4 application starting in development
* Listening on tcp://127.0.0.1:3000
Use Ctrl-C to stop
```


### Releasing new versions

Please refer to the dedicated [page](https://github.com/solidusio/solidus/wiki/How-to-release-extensions) on Solidus wiki.


## License

Copyright (c) 2016-2020 Stembolt and others contributors, released under the New BSD License
