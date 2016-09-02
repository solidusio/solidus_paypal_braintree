source 'https://rubygems.org'

branch = ENV.fetch("SOLIDUS_BRANCH", "master")
gem 'solidus', github: 'solidusio/solidus', branch: branch

if branch == "master" || branch >= "v2.0"
  gem "rails-controller-testing", group: :test
end

# Provides basic authentication functionality for testing parts of your engine
gem 'solidus_auth_devise', '~> 1.0'

group :development, :test do
  gem "pry-rails"
end

gemspec
