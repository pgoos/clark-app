# frozen_string_literal: true

# Contains Repository abstract class
# All other repository classes MUST be inherited from this class and implement abs method storage_path
# Custom methods COULD BE implemented in descendants

module Repository
  class Repository
    class << self
      def [](key)
        value = storage[key]
        raise KeyError.new("#{key} key was not found in #{storage_path}") if value.nil?
        value
      end

      private

      def storage
        YAML.safe_load(File.read(storage_path))
      end

      def storage_path
        raise NotImplementedError.new
      end
    end
  end
end
