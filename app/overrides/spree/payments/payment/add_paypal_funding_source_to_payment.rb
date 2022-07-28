# frozen_string_literal: true

Deface::Override.new(
  name: "payments/payment/add_paypal_funding_source_to_payment",
  virtual_path: "spree/payments/_payment",
  original: "0b5b5ae53626059cb3a202ef95d10827dd399925",
  insert_after: "erb[loud]:contains('content_tag(:span, payment.payment_method.name)')",
  partial: "solidus_paypal_braintree/payments/payment"
)
