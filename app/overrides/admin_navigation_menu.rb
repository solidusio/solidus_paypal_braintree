unless Spree::Backend::Config.respond_to?(:menu_items)
  Deface::Override.new(
    virtual_path: "spree/admin/shared/_settings_sub_menu",
    name: "solidus_paypal_braintree_admin_navigation_configuration",
    insert_bottom: "[data-hook='admin_settings_sub_tabs']",
    partial: "solidus_paypal_braintree/configurations/admin_tab"
  )
end
