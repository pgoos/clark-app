# frozen_string_literal: true

# == Schema Information
#
# Table name: offer_automations
#
#  id                              :integer          not null, primary key
#  name                            :string
#  state                           :string           default("inactive")
#  questionnaire_id                :integer
#  default_coverage_feature_idents :string           default([]), is an Array
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#

require "rails_helper"

RSpec.describe OfferAutomation, type: :model do
  context "with state machine" do
    it_behaves_like "an activatable model", :inactive

    it "should be a state scopable entity" do
      expect(subject).to be_a(StateScopable)
    end
  end

  context "with offer rules" do
    it { is_expected.to have_many(:offer_rules) }
  end

  describe "name" do
    it { is_expected.to validate_uniqueness_of(:name) }
  end

  context "with questionnaire" do
    it { is_expected.to belong_to(:questionnaire) }
    it { is_expected.to validate_presence_of(:questionnaire) }
  end

  context "with category" do
    before do
      subject.questionnaire = build_stubbed(:questionnaire)
    end

    it { expect(subject).to have_one(:category).through(:questionnaire) }
    it { is_expected.to be_valid }

    it "should validate it to be active", :integration do
      subject.questionnaire = create(:questionnaire, category: create(:category, state: "inactive"))
      expect(subject).not_to be_valid
    end
  end

  context "validations" do
    it "validates the presence of note_to_customer" do
      expect(subject).not_to validate_presence_of(:note_to_customer)
      subject.state = "active"
      expect(subject).to validate_presence_of(:note_to_customer).with_message(:blank)
    end

    context "default_coverage_feature_idents validations" do
      # https://github.com/thoughtbot/shoulda-matchers/issues/1007
      # validates_length_of of array is not supported by shoulda-matchers
      subject { build_stubbed(:offer_automation, note_to_customer: "note") }

      let(:few_idents) { Array.new(2).map { "coverage_ident" } }
      let(:acceptable_idents) { Array.new(11).map { "coverage_ident" } }

      it "validates the size of default_coverage_feature_idents" do
        subject.default_coverage_feature_idents = few_idents
        expect(subject).to be_valid

        subject.state = "active"
        subject.default_coverage_feature_idents = acceptable_idents
        expect(subject).to be_valid
        subject.default_coverage_feature_idents = few_idents
        expect(subject).not_to be_valid

        message = I18n.t(
          "activerecord.errors.models.offer_automation.attributes.default_coverage_feature_idents.wrong_amount"
        )
        expect(subject.errors[:default_coverage_feature_idents]).to eq [message]
      end
    end
  end

  context "with coverage features", :integration do
    let(:cov_feat1) { build(:coverage_feature) }
    let(:cov_feat2) { build(:coverage_feature) }
    let(:coverage_features) { [cov_feat1, cov_feat2] }
    let(:category) { create(:category, coverage_features: coverage_features) }
    let(:questionnaire) { create(:questionnaire, category: category) }

    before do
      subject.questionnaire = questionnaire
    end

    it "should return the configured coverage features" do
      expect(subject.coverage_feature_config).to eq(cov_feat1.identifier => false, cov_feat2.identifier => false)

      subject.default_coverage_feature_idents << cov_feat1.identifier
      expect(subject.coverage_feature_config).to eq(cov_feat1.identifier => true, cov_feat2.identifier => false)

      subject.default_coverage_feature_idents << cov_feat2.identifier
      subject.default_coverage_feature_idents.delete(cov_feat1.identifier)
      expect(subject.coverage_feature_config).to eq(cov_feat1.identifier => false, cov_feat2.identifier => true)
    end

    context "when loading the actual feature" do
      it "should load the actual feature by identifer" do
        expect(subject.coverage_feature(cov_feat1.identifier).identifier).to eq(cov_feat1.identifier)
        expect(subject.coverage_feature(cov_feat2.identifier).identifier).to eq(cov_feat2.identifier)
      end
    end
  end

  describe "language keys for validations" do
    %w[
      activerecord.errors.models.offer_automation.category.inactive
    ].each do |key|
      it { expect(I18n.t(key)).not_to match(/translation missing/) }
    end
  end
end
