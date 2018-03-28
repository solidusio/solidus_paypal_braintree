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

# bourbon 5 doesn't work under sassc
# https://github.com/thoughtbot/bourbon/issues/1047
gem 'bourbon', '<5'

group :development, :test do
  gem 'listen'
  gem "pry-rails"
  gem 'selenium-webdriver', require: false
  gem 'ffaker'

  gem 'pg', '~> 0.21'
  gem 'mysql2'
end

gemspec

gem 'solidus_support', github: 'tvdeyen/solidus_support', branch: 'cast-out-poltergeist'
