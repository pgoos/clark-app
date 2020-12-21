# frozen_string_literal: true

require "rails_helper"

describe "rake categories:remove_inactive_categories_from_at", type: :task do
  let!(:category_to_remove_1) { create(:category, ident: "4ce5f7e3") }
  let!(:category_to_remove_2) { create(:category, ident: "7383a451") }
  let!(:category_to_not_remove) { create(:category, ident: "sample_ident") }

  it "should remove selected categories" do
    expect { task.invoke }.to change(Category, :count).by(-2)
    expect(Category.all).not_to include([category_to_remove_1, category_to_remove_2])
    expect(Category.all).to include(category_to_not_remove)
  end
end

describe "rake categories:update_motorradversicherung_coverage_features", type: :task do
  let!(:other_category) {
    create(:category, ident: "4ce5f7e3", coverage_features: [
             CoverageFeature.new(
               identifier: "mntlcfda086f6f09f928d",
               name: "Example of coverage feature",
               definition: "Monatliche Berufsunfähigkeitsrente",
               value_type: "Money"
             ),
             CoverageFeature.new(
               identifier: "mntlcfda2928d",
               name: "Another sample name",
               definition: "One more different definition",
               value_type: "Money"
             )
           ])
  }
  let!(:motorradversicherun_category) {
    create(:category, ident: "360b6021", coverage_features: [
             CoverageFeature.new(
               identifier: "mntlcfda086f6f09f928d",
               name: "Example of coverage feature",
               definition: "Monatliche Berufsunfähigkeitsrente",
               value_type: "Money"
             ),
             CoverageFeature.new(
               identifier: "mntlcfda2928d",
               name: "Another sample name",
               definition: "One more different definition",
               value_type: "Text"
             )
           ])
  }

  it "should update coverage features definition and value_type only for Motorradversicherun" do
    task.invoke

    motorradverischerun_cat_coverage_features = Category.find_by(ident: "360b6021").coverage_features
    other_cat_coverage_features = Category.find_by(ident: "4ce5f7e3").coverage_features

    expect(motorradverischerun_cat_coverage_features.first.definition).to eq("Freitext")
    expect(motorradverischerun_cat_coverage_features.first.value_type).to eq("Text")
    expect(motorradverischerun_cat_coverage_features.second.definition).to eq("Freitext")
    expect(motorradverischerun_cat_coverage_features.second.value_type).to eq("Text")
    expect(other_cat_coverage_features.first.definition).to \
      eq("Monatliche Berufsunfähigkeitsrente")
    expect(other_cat_coverage_features.second.value_type).to eq("Money")
  end
end
