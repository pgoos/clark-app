# frozen_string_literal: true

require "rails_helper"

# TODO: Clean up this spec after executing this one time task in production
describe "rake category_coverage_features:update_section_attribute", type: :task do
  let!(:category) { create(:category_gkv) }
  let(:fixture_path) { "lib/tasks/category_coverage_features/section_mapping_de.json" }

  it "updates section attribute of category coverage_features" do
    task.invoke(fixture_path)

    coverage_features = Category.find(category.id).coverage_features

    expect(get_section(coverage_features, "boolean_spzlllstngnbbrnt_6bbfc9")).to eq("Weitere Leistungen")
    expect(get_section(coverage_features, "text_brnhmvnhmpth_9360b9")).to eq("Wichtigste Leistungen")
  end

  private

  def get_section(coverage_features, identifier)
    coverage_features.find { |cf| cf.identifier == identifier }.try(:section)
  end
end
