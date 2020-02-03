require 'vcr'
require 'webmock'

VCR.configure do |c|
  c.cassette_library_dir = "spec/fixtures/cassettes"
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.default_cassette_options = {
    match_requests_on: [:method, :uri, :body]
  }
  c.allow_http_connections_when_no_cassette = false
  c.ignore_localhost = true
  c.ignore_hosts 'chromedriver.storage.googleapis.com'

  # client token used for the fronted JS lib cannot be mocked:
  # it contains a cryptographically signed string containing the merchant id
  # that's sent back to braintree's server by the JS lib
  c.ignore_request do |request|
    !(request.uri =~ /\/merchants\/\w+\/client_token\z/).nil?
  end

  # match a request to Braintree sandbox APIs by ignoring the merchant ID
  # in the request URI
  c.register_request_matcher :braintree_uri do |request_1, request_2|
    extract_url_resource = lambda do |uri|
      uri_match_pattern =
        /\Ahttps:\/\/api\.sandbox\.braintreegateway\.com\/merchants\/\w+(\/.*)\z/

      if match = uri.match(uri_match_pattern)
        match.captures.first
      end
    end
    r1_resource = extract_url_resource.call(request_1.uri)
    r2_resource = extract_url_resource.call(request_2.uri)

    r1_resource != nil && r1_resource == r2_resource
  end

  # https://github.com/titusfortner/webdrivers/wiki/Using-with-VCR-or-WebMock
  driver_hosts = Webdrivers::Common.subclasses.map { |driver| URI(driver.base_url).host }
  c.ignore_hosts(*driver_hosts)
end
