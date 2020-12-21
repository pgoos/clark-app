# frozen_string_literal: true

# == Schema Information
#
# Table name: plans
#
#  id                     :integer          not null, primary key
#  name                   :string
#  state                  :string
#  plan_state_begin       :date
#  out_of_market_at       :date
#  created_at             :datetime
#  updated_at             :datetime
#  coverages              :jsonb
#  category_id            :integer
#  company_id             :integer
#  subcompany_id          :integer
#  metadata               :jsonb
#  insurance_tax          :float
#  ident                  :string
#  premium_price_cents    :integer          default(0)
#  premium_price_currency :string           default("EUR")
#  premium_period         :string
#

require "rails_helper"

RSpec.describe Plan, :slow, type: :model do

  # Setup

  subject { build(:plan, name: "Plan #1") }

  it { is_expected.to be_valid }

  # Settings

  it { is_expected.to monetize(:premium_price_cents) }

  # Constants
  # Attribute Settings

  %i[name state plan_state_begin].each do |attr|
    it { is_expected.to be_respond_to(attr) }
  end

  # Plugins
  # Concerns

  it_behaves_like "a commentable model"
  it_behaves_like "an activatable model"
  it_behaves_like "an auditable model"
  it_behaves_like "a model with coverages"
  it_behaves_like "an identifiable model"

  # Index
  # State Machine
  # Scopes
  # Associations

  it { expect(subject).to belong_to(:category) }
  it { expect(subject).to belong_to(:company) }
  it { expect(subject).to belong_to(:subcompany) }
  it { expect(subject).to belong_to(:parent_plan) }
  it { expect(subject).to have_many(:products).dependent(:restrict_with_error) }

  # Nested Attributes
  # Validations

  [:name].each do |attr|
    it { is_expected.to validate_presence_of(attr) }
  end

  context "with plan_state_begin uniqueness validation" do
    let!(:other_plan) do
      create(
        :plan,
        category: subject.category,
        plan_state_begin: subject.plan_state_begin,
        subcompany: subject.subcompany,
        name: subject.name
      )
    end

    let(:subcompany) { create(:subcompany) }

    it "validates correctly" do
      expect(subject).not_to be_valid

      subject.name = "New Plan Name"
      expect(subject).to be_valid

      subject.name = other_plan.name
      subject.subcompany = subcompany
      expect(subject).to be_valid

      other_plan.update!(plan_state_begin: nil)
      subject.plan_state_begin = nil
      expect(other_plan).to be_valid
    end
  end

  context "#formatted_plan_name" do
    it "validates correctly" do
      plan = build_stubbed(:plan, plan_state_begin: "2018-12-12")
      expect(plan.formatted_plan_name).to eq "* #{plan.name} - 12.12.2018"
      plan = build_stubbed(:plan, plan_state_begin: nil)
      expect(plan.formatted_plan_name).to eq plan.name
    end
  end

  context "#as_json" do
    it "returns the correct json payload" do
      plan = build_stubbed(:plan, name: "Plan name", plan_state_begin: nil)
      json = plan.as_json
      expect(json["name"]).to eq plan.name
      expect(json["formatted_plan_name"]).to eq plan.name

      plan = build_stubbed(:plan, name: "Plan name", plan_state_begin: "2018-12-12")
      json = plan.as_json
      expect(json["name"]).to eq plan.name
      expect(json["formatted_plan_name"]).to eq plan.formatted_plan_name
    end
  end

  # Callbacks
  # Delegates

  it { is_expected.to delegate_method(:category_ident).to(:category).as(:ident) }
  it { is_expected.to delegate_method(:category_combo?).to(:category).as(:combo?) }
  it { is_expected.to delegate_method(:vertical_ident).to(:category) }
  it { is_expected.to delegate_method(:company_name).to(:company).as(:name) }
  it { is_expected.to delegate_method(:company_ident).to(:company).as(:ident) }
  it { is_expected.to delegate_method(:documents).to(:plan_parent) }

  # Instance Methods

  describe "#category_and_name" do
    it "returns a string with the category name and plan name" do
      subject.category = build_stubbed(:category, name: "Cars")
      expect(subject.category_and_name).to eq("Cars - Plan #1")
    end
  end

  describe "#with_plan_state?" do
    it "returns true when the plan state is set" do
      plan1 = build_stubbed(:plan, plan_state_begin: Time.zone.today)
      expect(plan1.with_plan_state?).to eq true
      plan2 = build_stubbed(:plan, plan_state_begin: nil)
      expect(plan2.with_plan_state?).to eq false
    end
  end

  describe "company through subcompany" do
    let(:company) { create(:company) }
    let(:subcompany) { create(:subcompany, company: company) }

    it "returns the directly linked company when no subcompany is set" do
      subject.update(company: company, subcompany: nil)
      expect(subject.company).to eq(company)
    end

    it "returns the company that is linked to the subcompany" do
      subject.update(subcompany: subcompany, company: nil)
      expect(subject.company).to eq(company)
    end
  end

  # Class Methods

  describe "when the ident only is used", :integration do
    let(:ident1) { "ident1" }
    let(:ident2) { "ident2" }
    let(:ident3) { "ident3" }

    let(:plan1) { create(:plan, ident: ident1) }

    before do
      plan1
    end

    it "can check for the existence of a plan" do
      expect(Plan.exists_by_ident?(ident1)).to eq(true)
      expect(Plan.exists_by_ident?(ident2)).to eq(false)
    end

    it "can check for the existence of multiple plans" do
      expect(Plan.exists_by_ident?(ident1, ident2)).to eq(false)

      create(:plan, ident: ident2)
      expect(Plan.exists_by_ident?(ident1, ident2)).to eq(true)
    end

    it "can check if the plan is active" do
      create(:plan, ident: ident2, state: "inactive")
      expect(Plan.active_by_ident?(ident1)).to eq(true)
      expect(Plan.active_by_ident?(ident2)).to eq(false)
    end

    it "can check for multiple plans to be active" do
      create(:plan, ident: ident2)
      expect(Plan.active_by_ident?(ident1, ident2)).to eq(true)

      create(:plan, ident: ident3, state: "inactive")
      expect(Plan.active_by_ident?(ident1, ident2, ident3)).to eq(false)
    end

    it "extracts the category idents for given plan idents" do
      expect(Plan.category_idents_by_plan_idents(ident1)).to eq([plan1.category_ident])

      plan2 = create(:plan, ident: ident2)
      expect(Plan.category_idents_by_plan_idents(ident1, ident2)).to eq([plan1.category_ident, plan2.category_ident])

      create(:plan, ident: ident3, category: plan1.category)
      expect(Plan.category_idents_by_plan_idents(ident1, ident3)).to eq([plan1.category_ident])
    end
  end

  describe "#premium_state" do
    it "has correct premium_state with gkv category" do
      gkv_category = build_stubbed(:category_gkv)
      plan = build_stubbed(:plan, category: gkv_category)
      expect(plan.premium_state).to eq "salary"
    end

    it "has correct premium_state with other categories" do
      category = build_stubbed(:category)
      plan = build_stubbed(:plan, category: category)
      expect(plan.premium_state).to eq "premium"
    end
  end

  describe "#with_coverages" do
    let!(:plan_with_coverages) { create(:plan, :with_stubbed_coverages) }
    let!(:plan_without_coverages) { create(:plan) }

    it "shows the correct models" do
      expect(described_class.with_coverages).to eq [plan_with_coverages]
    end
  end

  # Protected
  # Private

end
