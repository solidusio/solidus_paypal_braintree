source 'https://rubygems.org'

branch = ENV.fetch("SOLIDUS_BRANCH", "master")
gem 'solidus', github: 'solidusio/solidus', branch: branch

gem 'rails-controller-testing'
if branch < "v2.5"
  gem 'factory_bot', '4.10.0'
else
  gem 'factory_bot', '> 4.10.0'
end

# Provides basic authentication functionality for testing parts of your engine
gem 'solidus_auth_devise', '~> 1.0'

# Asset compilation speed
gem 'mini_racer'
gem 'sassc-rails', platforms: :mri

# bourbon 5 doesn't work under sassc
# https://github.com/thoughtbot/bourbon/issues/1047
gem 'bourbon', '<5'

group :development, :test do
  gem 'listen'
  gem "pry-rails"
  gem 'selenium-webdriver', require: false
  gem 'chromedriver-helper', require: false
  gem 'ffaker'

  gem 'pg', '~> 0.21'
  gem 'mysql2'
end

gemspec
