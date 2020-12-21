# frozen_string_literal: true

require "yaml"

# TODO: refactor this. This should be a part of CucumberContext (or a result of its evolution) [JCLARK-57852]

module Repository
  module Credentials
    class CredentialsProvider
      CRED_STORAGE_PATH = Helpers::OSHelper.file_path("features", "support", "repository", "storage", "credentials.yaml")
      private_constant :CRED_STORAGE_PATH

      def ops_ui_admin_credentials
        if TestContextManager.instance.staging? || TestContextManager.instance.staging_2_20?
          username, password = parse_cred_from_env_vars
          { "username" => username, "password" => password }
        else
          YAML.safe_load(File.read(CRED_STORAGE_PATH))["ops_ui_admin"]["masterdata"]
        end
      end

      private

      def parse_cred_from_env_vars
        admin_email = ENV.fetch("CUCUMBER_ADMIN_EMAIL", nil)
        admin_password = ENV.fetch("CUCUMBER_ADMIN_PASSWORD", nil)
        admin_credentials = ENV.fetch("CUCUMBER_AUTOMATION_CREDS", nil)
        return admin_email, admin_password unless admin_email.nil? && admin_password.nil?
        return admin_credentials.split(":") unless admin_credentials.nil?
        raise ArgumentError.new("Cucumber admin credentials environment variables must be defined")
      end
    end

    def self.ops_ui_admin_credentials
      cred_provider = CredentialsProvider.new
      cred_provider.ops_ui_admin_credentials
    end
  end
end
