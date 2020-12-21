# frozen_string_literal: true

module Components
  # This component provides methods for interactions with lists of web elements
  module List
    # Method asserts that a list of objects exists and (optional) contains provided entities
    # DISPATCHER METHOD
    # Custom method MUST be implemented. Example: def assert_documents_list(table) { }
    # @param marker [String] custom method marker
    # @param table [Cucumber::Ast::Table] table of entities
    def assert_list(marker, table=nil)
      custom_method = "assert_#{marker.tr(' ', '_')}_list"
      send(custom_method, table)
    end
  end
end
