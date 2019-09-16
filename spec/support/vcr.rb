require 'vcr'
require 'webmock'

VCR.configure do |c|
  c.cassette_library_dir = "spec/fixtures/cassettes"
  c.hook_into :webmock
  c.ignore_localhost = true
  c.configure_rspec_metadata!
  c.default_cassette_options = {
    match_requests_on: [:method, :uri, :body]
  }
  c.allow_http_connections_when_no_cassette = false
  c.ignore_hosts 'chromedriver.storage.googleapis.com'
end
