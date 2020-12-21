# frozen_string_literal: true

require_relative "repository"

module Repository
  class PathTable < Repository
    class << self
      def page_navigable?(path_name)
        page_url = self[path_name]
        regex = %w((:?\d+) (:?.+))
        regex.none? { |value| page_url.include?(value) }
      end

      private

      def storage_path
        Helpers::OSHelper.file_path("features", "support", "repository", "storage", "path_table.yaml")
      end
    end
  end
end
