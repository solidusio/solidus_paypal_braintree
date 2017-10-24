source 'https://rubygems.org'

branch = ENV.fetch("SOLIDUS_BRANCH", "master")
gem 'solidus', github: 'solidusio/solidus', branch: branch

if branch == 'master' || branch >= "v2.3"
  gem "rails-controller-testing", group: :test
  gem 'rails', '~> 5.1.0' # HACK: broken bundler dependency resolution
elsif branch >= "v2.0"
  gem "rails-controller-testing", group: :test
  gem 'rails', '~> 5.0.3' # HACK: broken bundler dependency resolution
else
  gem "rails", '~> 4.2.0' # HACK: broken bundler dependency resolution
  gem "rails_test_params_backport", group: :test
end

# Provides basic authentication functionality for testing parts of your engine
gem 'solidus_auth_devise', '~> 1.0'

# Asset compilation speed
gem 'mini_racer'
gem 'sassc-rails', platforms: :mri

group :development, :test do
  gem 'listen'
  gem "pry-rails"
  gem 'selenium-webdriver', require: false
  gem 'chromedriver-helper', require: false
  gem 'ffaker'

  gem 'pg'
  gem 'mysql2'
end

gemspec
