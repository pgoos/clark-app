# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Products::GkvProductCreator do
  subject { Domain::Products::GkvProductCreator.new(mandate) }

  let(:gkv_coverage_feature_1) do
    CoverageFeature.new(name: "GKV Feature 1", definition: "GKV Feat 1 Desc.", value_type: "Text")
  end
  let(:gkv_coverage_features) { [gkv_coverage_feature_1] }
  let(:gkv_category) { create(:category_gkv, coverage_features: gkv_coverage_features) }
  let(:mandate) { create(:mandate, :accepted) }
  let(:company) { create(:gkv_company) }
  let(:inquiry) do
    create(:inquiry, mandate: mandate, company: company, state: "pending")
  end
  let(:inquiry_category) do
    create(:inquiry_category, category: gkv_category, inquiry: inquiry)
  end
  let(:gkv_coverage_1) { ValueTypes::Text.new("GKV coverage 1") }
  let(:gkv_coverages) { {gkv_coverage_feature_1.identifier => gkv_coverage_1} }
  let(:plan) do
    Plan.create(name: "GKV 1", company: company, category: gkv_category, coverages: gkv_coverages)
  end

  it "does nothing, if there is no GKV inquiry" do
    plan # the missing plan may not block the assertion .by(0)
    expect {
      subject.create_gkv_product
    }.to change { mandate.products.count }.by(0)
  end

  context "errors" do
    before { inquiry }

    it "fails if the related plan does not exist" do
      expect {
        subject.create_gkv_product
      }.to raise_error("No GVK plan for company with ident '#{company.ident}'")
    end

    it "fails for more than one gkv inquiry" do
      company2 = create(:gkv_company)
      create(:inquiry, mandate: mandate, company: company2, state: "pending")
      expect {
        subject.create_gkv_product
      }.to raise_error("Only 1 GKV inquiry allowed! Found 2!")
    end
  end

  context "creational states" do
    before do
      plan
    end

    %w[pending contacted].each do |state|
      it "should allow the creation of a gkv product for the state #{state}" do
        inquiry = create(:inquiry, mandate: mandate, company: company, state: state)
        create(:inquiry_category, category: gkv_category, inquiry: inquiry)
        expect {
          subject.create_gkv_product
        }.to change { mandate.products.count }.by(1)
      end
    end
  end

  context "plan exists" do
    before do
      inquiry
      inquiry_category
      plan
    end

    context "does nothing if the mandate is not in the state 'accepted'" do
      Mandate.state_machine.states.keys.except(:accepted).each do |state|
        it "ignores the state '#{state}'" do
          mandate.update_attributes!(state: state)
          expect {
            subject.create_gkv_product
          }.to change { mandate.products.count }.by(0)
        end
      end
    end

    it "creates GKV product with Plan when an inquiry for a GKV company is accepted" do
      expect {
        subject.create_gkv_product
      }.to change { mandate.products.count }.by(1)
    end

    it "does not create a second GKV product if one is present" do
      mandate.products << create(:product, inquiry: inquiry, plan: create(:plan, category: gkv_category, company: company))

      expect {
        subject.create_gkv_product
      }.to change { mandate.products.count }.by(0)
    end

    it "reuses the existing Plan" do
      expect {
        subject.create_gkv_product
      }.to change { Product.count }.by(1).and change { Plan.count }.by(0)
    end

    it "creates the coverages according to the plan" do
      subject.create_gkv_product
      expect(Product.last.coverages).to match_array(gkv_coverages)
    end

    it "completes the inquiry after the product was created" do
      subject.create_gkv_product
      inquiry.reload
      expect(inquiry).to be_completed
    end

    it "completes the inquiry category after the product was created" do
      subject.create_gkv_product
      inquiry_category.reload
      expect(inquiry_category).to be_completed
    end

    it "creates the complete and accept business events", :business_events do
      inquiry.update_attributes(state: "in_creation")
      BusinessEvent.audit_person = create(:admin)

      expect { inquiry.accept! }.to change {
        BusinessEvent.where(entity_type: "Inquiry").where.not(action: "update").count
      }.by(1)
    end

    it "chooses the active plan" do
      Plan.create(name: "GKV inactive", company: company, category: gkv_category, coverages: gkv_coverages, state: "inactive")
      plan
      Plan.create(name: "GKV inactive", company: company, category: gkv_category, coverages: gkv_coverages, state: "inactive")
      expect {
        subject.create_gkv_product
      }.to change { mandate.products.count }.by(1)
    end

    it "reduces the inquiries to one, if there are many for the same GKV company" do
      create(:inquiry, mandate: mandate, company: company, state: "pending")
      expect {
        subject.create_gkv_product
      }.to change { mandate.products.count }.by(1)
    end

    it "ignores a cancelled inquiry" do
      create(
        :inquiry,
        mandate: mandate,
        company: create(:gkv_company),
        state:   "canceled"
      )
      expect {
        subject.create_gkv_product
      }.to change { mandate.products.count }.by(1)
    end

    it "cancels duplicate inquiries for the same company" do
      duplicate1 = create(:inquiry, mandate: mandate, company: company, state: "pending")
      duplicate2 = create(:inquiry, mandate: mandate, company: company, state: "pending")
      subject.create_gkv_product
      duplicate1.reload
      duplicate2.reload
      expect(duplicate1).to be_canceled
      expect(duplicate2).to be_canceled
    end

    it "ignores already cancelled duplicate inquiries for the same company" do
      duplicate1 = create(:inquiry, mandate: mandate, company: company, state: "canceled")
      subject.create_gkv_product
      expect {
        duplicate1.reload
      }.not_to raise_error
    end

    it "cancels duplicate inquiry's inquiry categories" do
      duplicate1 = create(:inquiry, mandate: mandate, company: company, state: "pending")
      duplicate2 = create(:inquiry, mandate: mandate, company: company, state: "pending")
      inquiry_category1 = create(:inquiry_category, inquiry: duplicate1)
      inquiry_category2 = create(:inquiry_category, inquiry: duplicate2)
      subject.create_gkv_product
      inquiry_category1.reload
      inquiry_category2.reload
      expect(inquiry_category1).to be_cancelled
      expect(inquiry_category2).to be_cancelled
    end

    it "ignores already completed inquiry categories" do
      duplicate1 = create(:inquiry, mandate: mandate, company: company, state: "pending")
      create(:inquiry_category, inquiry: duplicate1, state: "completed")
      expect {
        subject.create_gkv_product
      }.not_to raise_error
    end

    it "ignores already cancelled inquiry categories" do
      duplicate1 = create(:inquiry, mandate: mandate, company: company, state: "pending")
      create(:inquiry_category, inquiry: duplicate1, state: "cancelled")
      expect {
        subject.create_gkv_product
      }.not_to raise_error
    end
  end
end
