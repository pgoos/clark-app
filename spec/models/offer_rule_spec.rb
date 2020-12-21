# frozen_string_literal: true

# == Schema Information
#
# Table name: offer_rules
#
#  id                                 :integer          not null, primary key
#  name                               :string
#  state                              :string           default("inactive")
#  offer_automation_id                :integer
#  category_id                        :integer
#  additional_coverage_feature_idents :string           default([]), is an Array
#  answer_values                      :jsonb
#  plan_idents                        :string           default([]), is an Array
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#  activated                          :boolean          default(FALSE)
#

require "rails_helper"

RSpec.describe OfferRule, type: :model do
  subject { OfferRule.new(offer_automation: build(:offer_automation, default_coverage_feature_idents: [])) }

  let(:sample_ident1) { "sample_ident1" }
  let(:sample_ident2) { "sample_ident2" }

  before do
    category = build_stubbed(:category, ident: "category_ident1")
    subject.category = category

    allow(Plan).to receive(:active_by_ident?).with(any_args).and_return(true)
    allow(Plan).to receive(:exists_by_ident?).with(any_args).and_return(true)
    allow(Plan).to receive(:category_idents_by_plan_idents).with(any_args).and_return([category.ident])
  end

  context "with offer automation" do
    it { is_expected.to belong_to(:offer_automation) }
    it { is_expected.to have_many(:offers).dependent(:restrict_with_error) }
    it { is_expected.to validate_presence_of(:offer_automation) }
  end

  context "when categories do not match", :integration do
    let(:category) { create(:category) }

    before do
      subject.category = category
      subject.name = "sample name"
    end

    context "with plans" do
      let(:plan1) { create(:plan, category: category) }
      let(:plan2) { create(:plan, category: category) }
      let(:wrong_plan) { create(:plan, category: create(:category)) }

      before do
        subject.plan_idents = [plan1.ident, plan2.ident, nil]

        # we need to reset the method call stubbing for the integration test:
        allow(Plan).to receive(:category_idents_by_plan_idents).with(any_args).and_call_original
      end

      it "should be valid if the plans' categories are of the same category" do
        expect(subject).to be_valid
      end

      it "should not be valid if one of the plans has a different category" do
        subject.plan_idents = [wrong_plan.ident, nil, nil]
        expect(subject).not_to be_valid
      end
    end

    describe "name" do
      it { is_expected.to validate_uniqueness_of(:name) }
      it { is_expected.to validate_presence_of(:name) }
    end
  end

  describe "with category" do
    it { expect(subject).to belong_to(:category) }
    it { is_expected.to validate_presence_of(:category) }

    it "should validate the category to be active" do
      category = build_stubbed(:category, state: "inactive")
      subject.category = category
      expect(subject).not_to be_valid
    end
  end

  describe "with plans" do
    before do
      subject.name = "sample name"
    end

    it "should be valid, if inactive and without a plan ident" do
      allow(Plan).to receive(:category_idents_by_plan_idents).and_call_original
      expect(subject).to be_valid
    end

    it "should provide an array with three values of nil as empty state" do
      expect(subject.plan_idents).to eq([nil, nil, nil])
    end

    it "should add a plan ident" do
      subject.plan_idents = [sample_ident1, nil, nil]
      expect(subject.plan_idents).to include(sample_ident1)
    end

    it "should take two plan idents" do
      subject.plan_idents = [sample_ident1, sample_ident2, nil]
      expect(subject.plan_idents).to eq([sample_ident1, sample_ident2, nil])
    end

    it "should take two plan idents with holes" do
      subject.plan_idents = [sample_ident1, nil, sample_ident2]
      expect(subject.plan_idents).to eq([sample_ident1, nil, sample_ident2])
    end

    it "should be valid if the plan is active" do
      subject.plan_idents = [sample_ident1, nil, nil]
      expect(subject).to be_valid
    end

    it "should not be valid if the plan is inactive" do
      allow(Plan).to receive(:active_by_ident?).with(sample_ident1).and_return(false)
      subject.plan_idents = [sample_ident1, nil, nil]
      expect(subject).not_to be_valid
    end

    it "should not be valid if one plan is inactive" do
      allow(Plan).to receive(:active_by_ident?).with(sample_ident1, sample_ident2).and_return(false)
      subject.plan_idents = [sample_ident1, sample_ident2, nil]
      expect(subject).not_to be_valid
    end

    it "should not be valid, if the rule is active, but no plan is attached" do
      subject.state = :active
      expect(subject).not_to be_valid
    end

    it "should fail, if the amount of plan idents is not 3" do
      [
        [],
        [nil],
        [nil, nil],
        [nil, nil, nil, nil]
      ].each do |plan_idents|
        subject.plan_idents = plan_idents
        expect(subject).not_to be_valid
      end
    end

    context "with plan option types" do
      before { subject.plan_idents = %w[first second third] }

      context "plan idents are valid" do
        context "plan option types are valid" do
          before do
            subject.plan_option_types = {
              "first" => :top_cover,
              "second" => :top_price,
              "third" => :top_cover_and_price
            }
          end

          it { expect(subject).to be_valid }
        end

        context "plan option types are invalid" do
          it "is invalid" do
            subject.plan_option_types = {
              "first" => :unknown_type,
              "second" => :top_price,
              "third" => :top_cover_and_price
            }
            expect(subject).not_to be_valid
          end
        end
      end

      context "plan idents are invalid" do
        it "is invalid" do
          subject.plan_option_types = {
            "unknown_ident" => :top_price,
            "second" => :top_cover,
            "third" => :top_cover_and_price
          }
          expect(subject).not_to be_valid
        end
      end
    end
  end

  describe "with coverage features" do
    let(:coverage_features) do
      result = []
      2.times do |i|
        result << build(:coverage_feature, identifier: "cov_feat_#{i}")
      end
      result
    end

    before do
      subject.category.coverage_features = coverage_features
    end

    context "when additional coverage features" do
      it "should add the coverage feature to the rule as unique entry" do
        identifier = coverage_features.first.identifier
        subject.additional_coverage_feature_idents = [identifier, identifier]
        expect(subject.additional_coverage_feature_idents).to eq([identifier])
      end

      it "should accept multiple coverage feature idents" do
        idents = coverage_features.map(&:identifier)
        subject.additional_coverage_feature_idents = idents
        expect(subject.additional_coverage_feature_idents).to eq(idents)
        expect(subject.additional_coverage_feature_idents.size > 1).to be_truthy
      end
    end

    context "when fetching displayed_coverage_features" do
      it "should use the additional coverage feature idents in the displayed ones" do
        identifier = coverage_features.first.identifier
        subject.additional_coverage_feature_idents = [identifier]

        expect(subject.displayed_coverage_features).to eq([identifier])
      end

      it "should add the offer automation's coverage feature idents into the additional ones" do
        default_idents = [coverage_features.first.identifier]
        subject.offer_automation.default_coverage_feature_idents = default_idents
        additional_idents = [coverage_features.last.identifier]
        subject.additional_coverage_feature_idents = additional_idents

        expect(subject.displayed_coverage_features).to eq(default_idents + additional_idents)
      end

      it "should remove duplicates between default and additional feature idents" do
        default_idents = [coverage_features.first.identifier]
        subject.offer_automation.default_coverage_feature_idents = default_idents
        subject.additional_coverage_feature_idents = default_idents

        expect(subject.displayed_coverage_features).to eq(default_idents)
      end
    end
  end

  context "with a note to the customer" do
    let(:separator) { "\n" }

    it "should use the note to the customer from the offer automation" do
      expected_text = "note from offer automation"
      subject.offer_automation.note_to_customer = expected_text
      expect(subject.note_to_customer).to eq(expected_text)
    end

    it "should use the postfix, if present" do
      expected_text_prefix = "note from offer automation"
      subject.offer_automation.note_to_customer = expected_text_prefix
      expected_text_postfix = "note from offer rule"
      subject.note_to_customer_postfix = expected_text_postfix
      expect(subject.note_to_customer).to eq(expected_text_prefix + separator + expected_text_postfix)
    end

    it "should strip whitespace" do
      white_space = " \t\r\n"
      expected_text_prefix = "note from offer automation"
      subject.offer_automation.note_to_customer = white_space + expected_text_prefix + white_space
      expected_text_postfix = "note from offer rule"
      subject.note_to_customer_postfix = white_space + expected_text_postfix + white_space
      expect(subject.note_to_customer).to eq(expected_text_prefix + separator + expected_text_postfix)
    end
  end

  describe "language keys for validations" do
    %w[
      activerecord.errors.models.offer_rule.category.inactive
      activerecord.errors.models.offer_rule.plans.inactive
      activerecord.errors.models.offer_rule.plans.count
      activerecord.errors.models.offer_rule.plans.wrong_categories
      activerecord.errors.models.offer_rule.plans.blank
    ].each do |key|
      it { expect(I18n.t(key)).not_to match(/translation missing/) }
    end
  end

  context "activatable", :integration do
    let(:random_seed) { rand(1..1000) }
    let(:category1) { create(:category, coverage_features: [build(:coverage_feature)]) }
    let(:category2) { create(:category, coverage_features: [build(:coverage_feature)]) }
    let(:plan1) { create(:plan, category: category1) }
    let(:plan2) { create(:plan, category: category1) }
    let(:plan3) { create(:plan, category: category1) }
    let(:plan4) { create(:plan, category: category1) }
    let(:plan5) { create(:plan, category: category1) }
    let(:question_identifier) { "question_identifier_#{random_seed}" }

    before do
      # we need to reset the method call stubbing for the integration test:
      allow(Plan).to receive(:category_idents_by_plan_idents).with(any_args).and_call_original

      subject.name = "Sample name #{random_seed}"
      subject.category = category1
      subject.plan_idents = [plan1.ident, plan2.ident, plan3.ident]
      subject.answer_values = {
        question_identifier => "Question response value #{random_seed}"
      }
      subject.save!
    end

    it_behaves_like "an activatable model", :inactive

    it "should be a state scopable entity" do
      expect(subject).to be_a(StateScopable)
    end

    it "is immutable as soon as it has been activated for the first time (except for the state attribute)" do
      expect(subject).to be_persisted

      # mutate the object, not yet activated:
      subject.name = "change 1 #{random_seed}"
      [plan1, plan2, plan3, plan4].each { |plan| plan.update!(category: category2) }
      subject.plan_idents[0] = plan4.ident
      subject.category = category2
      subject.additional_coverage_feature_idents << category2.coverage_features.first.identifier
      subject.answer_values[question_identifier] = "changed answer value 1 #{random_seed}"
      expect(subject).to be_valid

      subject.activate!
      expect(subject).to be_active

      # now the attributes should be immutable:
      check_immutability = lambda do |attribute_names|
        expect(subject).not_to be_valid
        attribute_names.each do |attribute_name|
          error = I18n.t("activerecord.errors.models.offer_rule.immutable_changed", attribute_name: attribute_name)
          expect(subject.errors.messages[attribute_name]).to include(error)
        end
        subject.reload
      end

      subject.name = "change 2 #{random_seed}"
      check_immutability.(%i[name])

      subject.answer_values[question_identifier] = "changed answer value 2 #{random_seed}"
      check_immutability.(%i[answer_values])

      subject.plan_idents = [plan5.ident]
      subject.category = category1
      subject.additional_coverage_feature_idents = [category1.coverage_features.first.identifier]
      check_immutability.(
        %i[
          plan_idents
          category_id
          additional_coverage_feature_idents
        ]
      )

      # we can still deactivate / activate the rule:
      expect(subject.deactivate).to be_truthy
      expect(subject.activate).to be_truthy
    end
  end
end
