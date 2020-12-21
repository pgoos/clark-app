# frozen_string_literal: true

require "support/shared_examples/behaves_like_a_coverage_feature"

RSpec.shared_examples "a coverage feature" do |name, args|
  include CoverageHelpers

  type = args[:type] || raise("Coverage feature type wasn't provided")
  value = args[:value] || raise("Coverage feature value wasn't provided")
  input_type = args[:input_type] || :select

  context "when value type of a feature is #{type}" do
    it "fills the feature" do
      add_coverage_feature(resource, name, type)
      visit edit_admin_product_path(resource.id, locale: locale)

      case input_type
      when :select
        i_select_coverage_feature("Feature", value)
      when :text
        i_fill_in_coverage_feature(name, value)
      when :date
        i_fill_in_coverage_feature(name, value, "raw_date")
      when :int
        i_fill_in_coverage_feature(name, value, "int")
      when :money
        i_fill_in_coverage_feature(name, value, "value")
      else
        raise "Unknown input type '#{type}'"
      end

      a_resource_is_updated(Product)
      i_see_coverage_feature(name, value)
    end
  end
end
