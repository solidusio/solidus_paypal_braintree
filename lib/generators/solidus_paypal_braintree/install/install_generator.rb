module SolidusPaypalBraintree
  module Generators
    class InstallGenerator < Rails::Generators::Base
      def install_braintree
        run 'bin/rails g solidus_braintree:install --auto_run_migrations=true'
      end
    end
  end
end
