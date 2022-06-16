# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

branch = ENV.fetch('SOLIDUS_BRANCH', 'master')
gem 'solidus', github: 'solidusio/solidus', branch: branch

gem 'rails', ENV.fetch('RAILS_VERSION', nil)

# Provides basic authentication functionality for testing parts of your engine
gem 'solidus_auth_devise'

# Asset compilation speed
gem 'mini_racer'
gem 'sassc-rails', platforms: :mri

gem 'bourbon'

case ENV.fetch('DB', nil)
when 'mysql'
  gem 'mysql2'
when 'postgresql'
  gem 'pg'
else
  gem 'sqlite3'
end

group :test do
  gem 'rails-controller-testing'
  gem 'webdrivers'
end

gemspec

# Use a local Gemfile to include development dependencies that might not be
# relevant for the project or for other contributors, e.g.: `gem 'pry-debug'`.
eval_gemfile 'Gemfile-local' if File.exist? 'Gemfile-local'
