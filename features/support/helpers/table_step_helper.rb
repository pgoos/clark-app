# frozen_string_literal: true

module Helpers
  # This module contains helper functions to work with Cucumber table objects
  module TableStepHelper
    module_function

    # Converts the first line of the Cucumber table into a Struct
    # @param table [Cucumber::MultilineArgument::DataTable]
    # @param struct [Struct]
    # @return [Struct] An instance of the target struct
    def build_single(table, struct)
      object = struct.new
      first_row = table.hashes.first
      first_row.each { |(key, value)| object[key] = value }
      object
    end

    # Converts the first line of the Cucumber table into an array of Struct
    # @param table [Cucumber::MultilineArgument::DataTable]
    # @param struct [Struct]
    # @return [Array<Struct>] An instance of the target struct
    def build_multiple(table, struct)
      table.hashes.map { |hash|
        object = struct.new
        hash.each { |(key, value)| object[key] = value }
        object
      }
    end
  end
end
