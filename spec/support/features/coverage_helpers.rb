# frozen_string_literal: true

module CoverageHelpers
  def add_coverage_feature(resource, coverage_feature_name, value_type)
    raise "Resource doesn't respond to #category message" unless resource.respond_to?(:category)

    category = resource.category
    coverage_feature_id = coverage_feature_name.gsub(/\s+/, "").snakecase
    coverage_feature_definition = "#{coverage_feature_name} Definition"

    category.coverage_features = [
      {
        "name" => coverage_feature_name,
        "genders" => nil,
        "definition" => coverage_feature_definition,
        "identifier" => coverage_feature_id,
        "valid_from" => Time.zone.now,
        "valid_until" => nil,
        "value_type" => value_type
      }
    ]

    category.save!
  end

  def i_select_coverage_feature(name, value)
    i_select_options(input_id(name, "value") => value)
  end

  def i_fill_in_coverage_feature(name, value, suffix="text")
    i_fill_in_text_fields(input_id(name, suffix) => value)
  end

  def i_see_coverage_feature(name, value)
    expect(page).to have_content("#{name} #{value}")
  end

  private

  def feature_name_to_snakecase(name)
    name.gsub(/\s+/, "").snakecase
  end

  def input_id(name, suffix=nil)
    "product_coverages_" + name.gsub(/\s+/, "").snakecase + (suffix ? "_#{suffix}" : "")
  end
end
