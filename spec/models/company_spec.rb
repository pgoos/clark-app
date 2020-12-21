# frozen_string_literal: true
# == Schema Information
#
# Table name: companies
#
#  id                                           :integer          not null, primary key
#  name                                         :string
#  state                                        :string
#  country_code                                 :string
#  logo                                         :string
#  info                                         :hstore
#  created_at                                   :datetime         not null
#  updated_at                                   :datetime         not null
#  national_health_insurance_premium_percentage :decimal(, )
#  average_response_time                        :integer
#  ident                                        :string
#  inquiry_blacklisted                          :boolean          default(FALSE)
#

require "rails_helper"

RSpec.describe Company, type: :model do
  # Setup

  subject { company }

  let(:company) { build(:company) }

  it { is_expected.to be_valid }

  # Settings
  # Constants
  # Attribute Settings

  %i[info info_phone damage_phone info_email damage_email b2b_contact_info mandates_email mandates_cc_email].each do |attr|
    it { is_expected.to be_respond_to(attr) }
  end

  # Plugins

  shared_examples "a model with normalized phone which depends on country_code column" do |*phone_number_fields|
    phone_number_fields.each do |phone_number_field|
      context "when country code is DE" do
        before { subject.country_code = "DE" }

        it_behaves_like "a model with normalized locale phone number field", phone_number_field, "+491771661253"
      end

      context "when country code is US" do
        before { subject.country_code = "US" }

        it_behaves_like "a model with normalized locale phone number field", phone_number_field, "+101771661253"
      end

      context "when country code is AT" do
        before { subject.country_code = "AT" }

        it_behaves_like "a model with normalized locale phone number field", phone_number_field, "+431771661253"
      end
    end
  end

  it_behaves_like "a model with normalized phone which depends on country_code column", :info_phone, :damage_phone

  # Concerns

  it_behaves_like "an identifiable for name model"
  it_behaves_like "a countrifiable model"
  it_behaves_like "a commentable model"
  it_behaves_like "an auditable model"

  # Index
  # State Machine
  # Scopes

  context "exclude_gkv" do
    it "does include companies with NHIPP=0" do
      company = create(:company, national_health_insurance_premium_percentage: 0)
      expect(Company.exclude_gkv).to include(company)
    end

    it "does include companies with NHIPP=nil" do
      company = create(:company, national_health_insurance_premium_percentage: nil)
      expect(Company.exclude_gkv).to include(company)
    end

    it "does not include compnanies with anything as NHIPP" do
      company = create(:company, national_health_insurance_premium_percentage: 1.5)
      expect(Company.exclude_gkv).not_to include(company)
    end
  end

  context "with_outstanding_inquiries" do
    let!(:company) { create(:company) }
    let!(:company_without) { create(:company) }
    let!(:inquiry) { create(:inquiry, company: company, state: "contacted") }

    it "finds companies with contacted inquiries" do
      expect(Company.with_outstanding_inquiries).to include(company)
    end

    it "returns a company only once even with multiple inquiries" do
      create(:inquiry, company: company, state: "contacted")
      actual_count   = Company.with_outstanding_inquiries.count
      expected_count = Company.with_outstanding_inquiries.to_set.count
      expect(actual_count).to eq(expected_count)
    end
  end

  context "with_outstanding_documents" do
    let!(:company) { create(:company) }
    let!(:plan) { create(:plan, company: company) }
    let!(:product) { create(:product, documents: [], plan: plan) }

    let!(:company_with_documents_at_products) { create(:company) }
    let!(:plan_with_documents_at_products) { create(:plan, company: company_with_documents_at_products) }
    let!(:product_with_document) { create(:product, plan: plan_with_documents_at_products) }

    let!(:document) { create(:document, document_type: DocumentType.policy, documentable: product_with_document) }

    it { expect(product_with_document.documents).not_to be_empty }

    it "finds companies with missing documents" do
      expect(Company.with_outstanding_documents).to match_array([company])
    end

    it "returns a company only once even with multiple products" do
      create(:product, documents: [], plan: plan)
      expect(Company.with_outstanding_documents.count).to eq(1)
    end
  end

  # Associations

  it { expect(subject).to have_many(:inquiries).dependent(:restrict_with_error) }
  it { expect(subject).to have_many(:subcompanies).dependent(:restrict_with_error) }
  it { expect(subject).to have_many(:plans).dependent(:restrict_with_error) }
  it { expect(subject).to have_many(:products).through(:plans) }

  context "products_with_missing_documents" do
    let!(:company) { create(:company) }
    let(:plan) { create(:plan, company: company) }

    it "includes products for this company" do
      product = create(:product, documents: [], plan: plan)
      expect(company.products_with_missing_documents).to include(product)
    end

    it "does not include products having a policy-like document" do
      product = create(:product, documents: [create(:document, document_type: DocumentType.policy)], plan: plan)
      expect(company.products_with_missing_documents).not_to include(product)
    end
  end

  context "outstanding_inquiries" do
    let!(:company) { create(:company) }
    let!(:inquiry) { create(:inquiry, company: company) }

    it "includes inquiries that are contacted" do
      inquiry.update_attributes(state: "contacted")
      expect(company.outstanding_inquiries).to include(inquiry)
    end

    (Inquiry.state_machine.states.map(&:name) - [:contacted]).each do |state|
      it "does not include inquiries in state #{state}" do
        inquiry.update_attributes(state: state)
        expect(company.outstanding_inquiries).not_to include(inquiry)
      end
    end
  end

  # Nested Attributes
  # Validations

  %i[name country_code].each do |attr|
    it { is_expected.to validate_presence_of(attr) }
  end

  it "validates country codes", :integration do
    expect(subject).to validate_inclusion_of(:country_code).in_array(ISO3166::Country.codes)
  end

  it_behaves_like "a model with email validation on", :info_email, :damage_email, :mandates_email, :mandates_cc_email

  # Callbacks

  context "after_create -> create_gkv_subcompany_and_plan" do
    let!(:vertical) { create(:vertical, ident: "GKV") }
    let!(:category) { create(:category_gkv, vertical: vertical) }

    it "creates a GKV subcompany and a plan if a company is created as a GKV" do
      company = nil

      expect do
        company = create(:company, national_health_insurance_premium_percentage: 0.7)
      end.to change(Subcompany, :count).by(1).and change(Plan, :count).by(1)

      subcompany = company.subcompanies.first
      plan = subcompany.plans.first

      expect(subcompany.name).to eq(company.name)
      expect(subcompany.verticals.size).to eq(1)
      expect(subcompany.verticals.first.ident).to eq("GKV")
      expect(plan.name).to eq("gesetzliche Krankenversicherung")
      expect(plan.category).to eq(category)
    end
  end

  # Delegates
  # Instance Methods
  # Class Methods
end
