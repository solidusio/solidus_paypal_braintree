RSpec.configure do |config|
  config.before(:each, type: :feature, js: true) do
    page.driver.browser.manage.window.resize_to(1600, 1024)
  end
end
