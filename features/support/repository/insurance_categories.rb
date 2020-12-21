# frozen_string_literal: true

require_relative "repository"

module Repository
  class InsuranceCategories < Repository
    class << self
      private

      def storage_path
        Helpers::OSHelper.file_path("features", "support", "repository", "storage", "insurance_categories.yaml")
      end
    end
  end
end
