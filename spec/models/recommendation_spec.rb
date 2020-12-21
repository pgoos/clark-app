# frozen_string_literal: true
# == Schema Information
#
# Table name: recommendations
#
#  id           :integer          not null, primary key
#  mandate_id   :integer
#  category_id  :integer
#  level        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  is_mandatory :boolean          default(FALSE)
#  dismissed    :boolean          default(FALSE)
#

require "rails_helper"

RSpec.describe Recommendation, type: :model do

  # Setup
  # Settings
  # Constants
  # Attribute Settings
  # Plugins
  # Concerns

  it_behaves_like "an auditable model"

  # State Machine
  # Scopes

  context "by_category_idents" do
    let(:mandate) { create(:mandate) }
    let(:category_kfz) { create(:category_kfz) }
    let(:category_phv) { create(:category_phv) }
    let(:category_hr) { create(:category_hr) }
    let(:kfz_recommendation) do
      create(:recommendation, mandate: mandate, category: category_kfz)
    end
    let(:phv_recommendation) do
      create(:recommendation, mandate: mandate, category: category_phv)
    end

    let(:recommendations) { mandate.recommendations }

    before do
      kfz_recommendation
      phv_recommendation
      category_hr
    end

    it "should return an empty collection if recommendation not given" do
      expect(recommendations.by_category_idents([category_hr.ident])).to be_empty
    end

    it "should return a collection with a single recommendation if given" do
      by_category_idents = recommendations.by_category_idents([category_kfz.ident])
      expect(by_category_idents).to match_array([kfz_recommendation])
    end

    it "should return a collection with all matching recommendations if given" do
      by_category_idents = recommendations.by_category_idents([category_kfz.ident, category_phv.ident])
      expect(by_category_idents).to match_array([kfz_recommendation, phv_recommendation])
    end
  end

  context "without_life_aspect" do
    let(:mandate) { create(:mandate) }
    let(:kfz_recommendation) do
      create(:recommendation, mandate: mandate, category: create(:category_kfz, life_aspect: "health"))
    end

    let(:retirement_recommendation) do
      create(:recommendation, mandate: mandate, category: create(:category, life_aspect: "retirement"))
    end

    let(:recommendations) { mandate.recommendations }

    before do
      kfz_recommendation
      retirement_recommendation
      recommendations
    end

    it "should return recommendations without retirement as life aspect" do
      without_life_aspect = recommendations.without_life_aspect("retirement")
      expect(without_life_aspect).to match_array([kfz_recommendation])
    end
  end

  context "active" do
    let(:mandate) do
      mandate = create(:mandate)
      create(:recommendation, mandate: mandate, dismissed: true)
      create_list(:recommendation, 2, mandate: mandate)
      mandate
    end

    it "should return active recommendations" do
      expect(mandate.recommendations.count).to be(3)

      active_recommendations = mandate.recommendations.active
      expect(active_recommendations.count).to be(2)
      expect(active_recommendations.map(&:dismissed)).to all(be false)
    end
  end

  context "reject_by_category" do
    let(:blacklist) { %w[1ded8a0f 3659e48a] }
    let(:category_idents) { %w[1ded8a0f 3659e48a abcd1234] }
    let(:mandate) { create(:mandate) }
    let(:categories) { category_idents.map { |ident| create(:category, ident: ident) } }

    let!(:recommendations) do
      categories.map { |category| create(:recommendation, mandate: mandate, category: category) }
    end

    it "should reject recommendations for blacklisted categories" do
      stub_const("Recommendation::BLACKLISTED_CATEGORIES", [])

      filtered_recommendations = mandate.recommendations.reject_by_category
      expect(filtered_recommendations.count).to be(3)

      stub_const("Recommendation::BLACKLISTED_CATEGORIES", blacklist)

      filtered_recommendations = mandate.recommendations.reject_by_category
      expect(filtered_recommendations.count).to be(1)
      expect(filtered_recommendations.first.category.ident).to eql("abcd1234")
    end
  end

  # Associations

  it { expect(subject).to belong_to(:mandate) }
  it { expect(subject).to belong_to(:category) }

  # Nested Attributes
  # Validations

  it { expect(subject).to validate_presence_of(:mandate) }
  it { expect(subject).to validate_presence_of(:category) }
  it do
    create(:recommendation, mandate: create(:mandate), category: create(:category))
    expect(subject).to validate_uniqueness_of(:category_id).scoped_to(:mandate_id)
  end

  it { expect(subject).to validate_inclusion_of(:level).in_array(Settings.attribute_domains.recommendation_levels.map(&:to_s)) }

  # Callbacks

  # Delegates

  it { is_expected.to delegate_method(:life_aspect).to(:category) }
  it { is_expected.to delegate_method(:questionnaire_identifier).to(:category) }
  it { is_expected.to delegate_method(:category_ident).to(:category).as(:ident) }
  it { is_expected.to delegate_method(:category_priority).to(:category).as(:priority) }
  it { is_expected.to delegate_method(:category_name).to(:category).as(:name) }

  # Instance Methods

  describe "#dismiss" do
    let(:recommendation) { create(:recommendation, mandate: create(:mandate), category: create(:category)) }

    it "defaults the newly created recommendation dismissed attribute to false by default" do
      expect(recommendation.dismissed).to eq(false)
    end

    it "marks the recommendation as dismissed" do
      recommendation.dismiss
      expect(recommendation.dismissed).to eq(true)
    end
  end

  # Class Methods
end
