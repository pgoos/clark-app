# frozen_string_literal: true

# == Schema Information
#
# Table name: categories
#
#  id                           :integer          not null, primary key
#  state                        :string
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  vertical_id                  :integer
#  ident                        :string           not null
#  coverage_features            :jsonb            not null
#  icon                         :string
#  starting_price_cents         :integer
#  starting_price_currency      :string           default("EUR")
#  content_page_href            :string
#  description                  :text
#  background_image             :string
#  background_image_mobile      :string
#  search_tokens                :string
#  overview_image_short         :string
#  overview_image_long          :string
#  termination_period           :integer
#  priority                     :integer          default(1)
#  average_price_cents          :integer
#  average_price_currency       :string           default("EUR")
#  cover_benchmark              :integer
#  product_detail_image_file_id :integer
#  ff_type                      :string
#  premium_type                 :string           default("gross")
#  questionnaire_id             :integer
#  advice_templates             :jsonb
#  included_category_ids        :integer          default([]), is an Array
#  category_type                :string           default("regular")
#  simple_checkout              :boolean          default(FALSE)
#  offer_templates              :jsonb
#  metadata                     :jsonb
#  life_aspect                  :string
#  profit_margin                :integer          default("unspecified")
#  plan_filter_id               :integer
#  tax_rate                     :float
#

require "rails_helper"

RSpec.describe Category, type: :model do
  # Setup
  subject(:category) { build(:category) }

  # it { is_expected.to be_valid }

  # Settings
  # Constants

  # Attribute Settings
  it { is_expected.to monetize(:average_price) }

  # Concerns

  it_behaves_like "a commentable model"
  it_behaves_like "an activatable model"
  it_behaves_like "an identifiable model"
  it_behaves_like "an auditable model"

  # State Machine
  # Scopes
  describe ".by_name" do
    it "filters out categories by name" do
      create :category, name: "FOO"
      cat = create :category, name: "BAR"

      expect(described_class.by_name("BAR")).to eq [cat]
    end
  end

  # Associations

  it { is_expected.to belong_to(:vertical) }
  it { expect(subject).to have_many(:recommendations) }
  it { expect(subject).to have_many(:plans).dependent(:restrict_with_error) }
  it { is_expected.to have_many(:plan_filters) }
  it { is_expected.to belong_to(:plan_filter) }

  context "multi-category-categories" do
    let(:category_a)         { create(:category) }
    let(:category_b)         { create(:category) }
    let(:category_c)         { create(:category) }
    let!(:combo_category)    { create(:combo_category,    included_categories: [category_a]) }
    let!(:umbrella_category) { create(:umbrella_category, included_categories: [category_b]) }

    it "can not include itself" do
      combo_category.included_category_ids << combo_category.id
      expect(combo_category).not_to be_valid
      expect(combo_category.errors[:included_category_ids]).to be_present
    end

    context "nesting" do
      it "does not allow to add ubmrella to combo" do
        combo_category.included_category_ids << umbrella_category.id

        expect(combo_category).not_to be_valid
        expect(combo_category.errors[:included_category_ids]).to be_present
      end

      it "does not allow to add combo to combo" do
        combo_category2 = create(:combo_category, included_categories: [category_b])
        combo_category.included_category_ids << combo_category2.id

        expect(combo_category).not_to be_valid
        expect(combo_category.errors[:included_category_ids]).to be_present
      end

      it "does not allow to add umbrella to umbrella" do
        category = create(:category)
        umbrella_category2 = create(:umbrella_category, included_categories: [category])
        umbrella_category.included_category_ids << umbrella_category2.id

        expect(umbrella_category).not_to be_valid
        expect(umbrella_category.errors[:included_category_ids]).to be_present
      end

      it "does allow to add combo to umbrella" do
        umbrella_category.included_category_ids << combo_category.id
        expect(umbrella_category).to be_valid
      end
    end

    it "gets the category models with #included_categories" do
      combo_category.update_attributes(included_category_ids: [category_b.id, category_c.id])
      expect(combo_category.included_categories).to match_array([category_b, category_c])
    end

    it "can not be deleted if they are included in another category" do
      expect(category_a.destroy).to be_falsey
      expect(category_a.errors[:base].first).to match(/#{combo_category.name}/)
    end
  end

  # Nested Attributes
  # Validations

  it { is_expected.to have_db_column(:enabled_for_advice) }

  it do
    expect(subject).to validate_inclusion_of(:ff_type).in_array(Settings.attribute_domains.ff_type)
  end

  it do
    expect(subject).to validate_inclusion_of(:premium_type)
      .in_array(Settings.attribute_domains.premium_type)
  end

  %i[name vertical].each do |attr|
    it { is_expected.to validate_presence_of(attr) }
  end

  # Create a real database object to satisfy the unique validation
  it { expect(create(:category)).to validate_uniqueness_of(:ident).case_insensitive }

  describe "#default_renewal_period" do
    subject { category.default_renewal_period }

    context "with suhk vertical" do
      let(:category) { build_stubbed(:category, :suhk) }

      it { is_expected.to eq 12 }
    end

    context "without suhk vertical" do
      let(:category) { build_stubbed(:category) }

      it { is_expected.to be_nil }
    end
  end

  context "validations for category types" do
    context "regular" do
      before { subject.category_type = Category.category_types[:regular] }

      it "is valid when included_categories is empty" do
        subject.included_category_ids = []
        expect(subject).to be_valid
      end

      it "is not valid when it has included_categories" do
        subject.included_category_ids = [1, 2, 3]
        expect(subject).not_to be_valid
      end
    end

    context "umbrella" do
      before { subject.category_type = Category.category_types[:umbrella] }

      it "is not valid when included_categories is empty" do
        subject.included_category_ids = []
        expect(subject).not_to be_valid
      end

      it "is valid when it has included_categories" do
        subject.included_category_ids = [1, 2, 3]
        expect(subject).to be_valid
      end
    end

    context "combo" do
      before { subject.category_type = Category.category_types[:combo] }

      let(:sample_category) { create(:category) }

      it "is not valid when included_categories is empty" do
        subject.included_category_ids = []
        expect(subject).not_to be_valid
      end

      it "is valid when it has included_categories" do
        subject.included_category_ids = [sample_category.id]
        expect(subject).to be_valid
      end
    end
  end

  context "uniqueness of combos" do
    let!(:category_a)     { create(:category) }
    let!(:category_b)     { create(:category) }
    let!(:category_c)     { create(:category) }
    let!(:combo_category) { create(:combo_category, included_categories: [category_a, category_b]) }

    it "does not allow to create another combo with the same categories" do
      new_combo = FactoryBot.build(:combo_category, included_categories: [category_a, category_b])
      expect(new_combo).not_to be_valid
      expect(new_combo.errors[:included_category_ids].count).to eq(1)
    end

    it "does not allow to create combo when the included categories are ordered differently" do
      new_combo = FactoryBot.build(:combo_category, included_categories: [category_b, category_a])
      expect(new_combo).not_to be_valid
      expect(new_combo.errors[:included_category_ids].count).to eq(1)
    end

    it "allows creation of a narrower combo (less elements)" do
      new_combo = FactoryBot.build(:combo_category, included_categories: [category_a])
      expect(new_combo).to be_valid
    end

    it "allows creation of a wider combo (more elements)" do
      new_combo = FactoryBot.build(:combo_category, included_categories: [category_a, category_b, category_c])
      expect(new_combo).to be_valid
    end

    it "allows creation of an umbrella with the same categories as a combo" do
      new_umbrella = FactoryBot.build(:umbrella_category, included_categories: combo_category.included_categories)
      expect(new_umbrella).to be_valid
    end
  end

  # Callbacks

  it "generates a name for combo categories based on included categories" do
    category = create(:combo_category, included_categories: [
                        create(:category, name: "KFZ-Vollkasko-Versicherung", priority: 100),
                        create(:category, name: "KFZ-Haftpflichtversicherung", priority: 50),
                        create(:category, name: "KFZ-Schutzbrief", priority: 10)
                      ])

    expect(category.name).to eq("KFZ-Vollkasko- & KFZ-Haftpflichtversicherung (mit Schutzbrief)")
  end

  context "sanitizes array attributes removing empty elements before saving" do
    %i[tips benefits quality_standards_features
       selection_guidelines rating_criteria clark_warranty].each do |method|
      it method.to_s do
        cat = create(:category)
        cat.send("#{method}=", ["value1", "", nil, "value2"])
        cat.save!
        expect(cat.send(method)).to eq(%w[value1 value2])
      end
    end
  end

  # Instance Methods

  context "gkv product" do
    context "is gkv category" do
      let(:category_gkv) { create(:category_gkv) }
      let(:category)     { create(:category) }

      it { is_expected.to delegate_method(:questionnaire_identifier).to(:questionnaire).as(:identifier) }
      it { is_expected.to delegate_method(:vertical_ident).to(:vertical).as(:ident) }

      it "delegates vertical_ident to vertical.ident" do
        expect(subject.vertical.ident).to be_present
        expect(subject.vertical_ident).to eq(subject.vertical.ident)
      end

      it "should be gkv if gkv category" do
        expect(category_gkv.gkv?).to eq(true)
      end

      it "should return false if not gkv category" do
        expect(category.gkv?).to eq(false)
      end
    end

    context "is gkv related category" do
      let(:category_gkv_related) { create(:category) }
      let(:category) { create(:category) }

      before do
        category_gkv_related.update_attributes(ident: "kranken")
        category.update_attributes(ident: "ThisShouldNeverBeThere")
      end

      it "should return correctly for the new flag if it is gkv related" do
        expect(category_gkv_related.is_gkv_related?).to eq(true)
        expect(category.is_gkv_related?).to eq(false)
      end
    end
  end

  describe "#grv?" do
    it "returns true if the category is a grv" do
      grv_category = build(:category, ident: described_class.grv_ident)
      expect(grv_category).to be_grv
    end

    it "returns false if the category is not a grv" do
      grv_category = build(:category, ident: described_class.phv_ident)
      expect(grv_category).not_to be_grv
    end
  end

  context "coverage features" do
    it "serializes CoverageFeatures into the json column" do
      cat = create(:category)
      coverage_feature = CoverageFeature.new(
        "name"        => "Deckungssumme",
        "definition"  => "...",
        "identifier"  => "cvrgftr1",
        "order" => nil,
        "section" => nil,
        "description" => "desc",
        "valid_from"  => "2015-01-01T12:00:00.000+00:00",
        "value_type"  => "Money",
        "valid_until" => nil
      )
      cat.instance_variable_set :@coverage_features, [coverage_feature]
      cat.save

      cat.reload

      expect(cat.read_attribute(:coverage_features)).to eq(
        [{
          "name" => "Deckungssumme",
          "genders" => nil,
          "definition"  => "...",
          "identifier"  => "cvrgftr1",
          "order" => nil,
          "section" => nil,
          "description" => "desc",
          "valid_from"  => "2015-01-01T12:00:00.000+00:00",
          "value_type"  => "Money",
          "valid_until" => nil
        }]
      )
    end

    context "getter" do
      it "returns CoverageFeature objects rendered from JSON Column" do
        coverage_features_array = [
          {
            "name"        => "Deckungssumme",
            "definition"  => "...",
            "identifier"  => "cvrgftr1",
            "valid_from"  => "2015-01-01T12:00:00.000+00:00",
            "value_type"  => "Money",
            "valid_until" => nil
          },
          {
            "name"        => "Sonstige Informationen",
            "definition"  => "...",
            "identifier"  => "cvrgftr2",
            "valid_from"  => "2015-01-01T12:00:00.000+00:00",
            "value_type"  => "Text",
            "valid_until" => nil
          }
        ]

        category = create(:category, coverage_features: coverage_features_array)

        features = category.coverage_features

        expect(features.size).to eq(2)
        expect(features.first).to be_kind_of(CoverageFeature)
        expect(features.first.name).to eq("Deckungssumme")

        expect(features.last).to be_kind_of(CoverageFeature)
        expect(features.last.name).to eq("Sonstige Informationen")
      end

      it "returns ordered CoverageFeature objects from JSON Column" do
        coverage_features_array = [
          {
            "name" => "Deckungssumme",
            "definition" => "...",
            "identifier" => "cvrgftr1",
            "order" => 1,
            "valid_from" => "2015-01-01T12:00:00.000+00:00",
            "value_type" => "Money",
            "valid_until" => nil
          },
          {
            "name" => "Sonstige Informationen",
            "definition" => "...",
            "identifier" => "cvrgftr2",
            "order" => 0,
            "valid_from" => "2015-01-01T12:00:00.000+00:00",
            "value_type" => "Text",
            "valid_until" => nil
          }
        ]

        category = create(:category, coverage_features: coverage_features_array)

        features = category.coverage_features

        expect(features.size).to eq(2)
        expect(features.first).to be_kind_of(CoverageFeature)
        expect(features.first.name).to eq("Sonstige Informationen")

        expect(features.last).to be_kind_of(CoverageFeature)
        expect(features.last.name).to eq("Deckungssumme")
      end
    end

    context "setter" do
      let(:category) { create(:category, coverage_features: []) }

      it "sets coverage_features from models and hashes" do
        coverage_features_array = [
          CoverageFeature.new(
            name:        "Deckungssumme",
            definition:  "...",
            identifier:  "cvrgftr1",
            valid_from:  nil,
            value_type:  "Money",
            valid_until: nil
          ),
          {
            "name"        => "Sonstige Informationen",
            "definition"  => "...",
            "identifier"  => "cvrgftr2",
            "valid_from"  => "2015-01-01T12:00:00.000+00:00",
            "value_type"  => "Text",
            "valid_until" => nil
          }
        ]

        category.coverage_features = coverage_features_array

        category.save
        category.reload

        features_array = category.read_attribute(:coverage_features)

        expect(features_array.count).to eq(2)
        expect(features_array.first["name"]).to eq("Deckungssumme")
        expect(features_array.last["name"]).to eq("Sonstige Informationen")
      end

      it "raises an error when trying to use the setter with an hash" do
        expect { category.coverage_features = {} }.to raise_error(ArgumentError)
      end

      it "does not overwrite existing coverage features" do
        coverage_feature1 = CoverageFeature.new(
          name:       "Feature 1",
          definition: "Definition 1",
          identifier: "ident1",
          value_type: "Text"
        )
        coverage_feature2 = CoverageFeature.new(
          name:       "Feature 2",
          definition: "Definition 2",
          identifier: "ident2",
          value_type: "Text"
        )
        category.coverage_features = [coverage_feature1, coverage_feature2]

        coverage_feature_new = CoverageFeature.new(
          name:       "Feature new",
          definition: "Definition new",
          identifier: "identnew",
          value_type: "Text"
        )

        category.coverage_features = [coverage_feature_new]
        category.save!
        expected_features = [coverage_feature1, coverage_feature2, coverage_feature_new]
        expect(category.coverage_features).to match_array(expected_features)
      end

      it "can infer the value type of an existing coverage feature" do
        value_type = "Text"
        identifier = "ident1"
        coverage_feature = CoverageFeature.new(
          name:       "Feature 1",
          definition: "Definition 1",
          identifier: identifier,
          value_type: value_type
        )
        category.coverage_features = [coverage_feature]
        category.save!
        altered_definition = "altered definition"
        coverage_feature.definition = altered_definition

        category.coverage_features = [coverage_feature.attributes.except(:value_type)]
        category.save!

        saved_feature = category.coverage_features.first
        expect(saved_feature.identifier).to eq(identifier)
        expect(saved_feature.value_type).to eq(value_type)
        expect(saved_feature.definition).to eq(altered_definition)
      end

      it "allows to change existing coverage features" do
        shared_ident = "ident1"
        coverage_feature1 = CoverageFeature.new(
          name:       "Feature 1",
          definition: "Definition 1",
          identifier: shared_ident,
          value_type: "Text"
        )
        coverage_feature2 = CoverageFeature.new(
          name:       "Feature 2",
          definition: "Definition 2",
          identifier: "ident2",
          value_type: "Text"
        )
        category.coverage_features = [coverage_feature1, coverage_feature2]
        category.save!

        coverage_feature_modified = CoverageFeature.new(
          name:       "Feature 1 modified",
          definition: "Definition 1 modified",
          identifier: shared_ident,
          value_type: "Text"
        )

        category.coverage_features = [coverage_feature_modified]
        expected_features = [coverage_feature_modified, coverage_feature2]
        expect(category.coverage_features).to match_array(expected_features)
      end
    end

    context "for combo categories" do
      let(:category_a) { create(:category, coverage_features: [FactoryBot.build(:coverage_feature)]) }
      let(:category_b) { create(:category, coverage_features: [FactoryBot.build(:coverage_feature)]) }
      let!(:category)  { create(:combo_category, coverage_features: [], included_categories: [category_a, category_b]) }

      it "returns coverage_features from the included categories when no features are set" do
        expect(category.coverage_features.count).to eq(2)
        expect(category.coverage_features.map(&:identifier))
          .to match_array((category_a.coverage_features + category_b.coverage_features)
          .map(&:identifier))
      end
    end
  end

  describe "#simple_checkout?" do
    %w[regular umbrella].each do |type|
      [true, false].each do |value|
        it "returns the provided value (#{value}) for #{type} categories" do
          category = FactoryBot.build(:category, category_type: type, simple_checkout: value)
          expect(category.simple_checkout?).to eq(value)
        end
      end
    end

    it "returns true when all categories in a combo have simple checkout" do
      category = create(
        :combo_category,
        included_categories: [create(:category, simple_checkout: true),
                              create(:category, simple_checkout: true)]
      )
      expect(category).to be_simple_checkout
    end

    it "returns false when one category in a combo does not have simple checkout" do
      category = create(
        :combo_category,
        included_categories: [create(:category, simple_checkout: false),
                              create(:category, simple_checkout: true)]
      )
      expect(category).not_to be_simple_checkout
    end
  end

  # Class Methods

  context "combo category inclusion finder" do
    let(:category_not_included)    { create(:category, ident: "not_incl") }
    let(:category_included)        { create(:category, ident: "incl") }
    let(:category_included_other) { create(:category, ident: "incl_other") }
    let!(:combo_category) { create(:combo_category, ident: "combo", included_categories: [category_included]) }
    let!(:other_combo_category) do
      create(:combo_category, ident: "other_combo", included_categories: [category_included_other])
    end

    it "works for empty array" do
      expect(::Category.find_combos_with_idents([])).to match([])
    end

    it "finds nothing for random idents" do
      expect(::Category.find_combos_with_idents(["sdfsdf"])).to match([])
    end

    it "finds combos with included idents" do
      expect(::Category.find_combos_with_idents(["incl"])).to match(["combo"])
    end

    it "does not find regular categories that are not in combos" do
      expect(::Category.find_combos_with_idents(["not_incl"])).to match([])
    end
  end
end
