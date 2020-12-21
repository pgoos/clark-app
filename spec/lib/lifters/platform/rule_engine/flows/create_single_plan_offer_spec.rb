# frozen_string_literal: true

require "rails_helper"

RSpec.describe Platform::RuleEngineV3::Flows::CreateSinglePlanOffer do
  subject { described_class }

  let!(:category) { create(:category) }
  let(:coverage_feature_1) { FactoryBot.build(:coverage_feature) }
  let(:coverage_feature_2) { FactoryBot.build(:coverage_feature) }
  let(:coverage_feature_3) { FactoryBot.build(:coverage_feature) }
  let(:coverage_features) { [coverage_feature_1, coverage_feature_2, coverage_feature_3] }
  let(:opportunity) { create(:opportunity, category: category) }
  let(:company) { create(:company) }
  let(:recommended_plan) { create(:plan, category: category, company: company) }
  let(:sample_offer_text_key) { "legal_protection.offer_text" }
  let(:note_to_customer) { I18n.t("automation.#{sample_offer_text_key}", unternehmen: company.name) }

  let(:recommended_option_config) { plan_conf(recommended_plan.ident, :top_cover_and_price, true) }
  let(:non_existing_plan_config) { plan_conf("unknown_plan_#{rand(100)}") }

  let(:offer) do
    intent = subject.new(
      opportunity,
      sample_offer_text_key,
      recommended_option_config
    )
    intent.call
  end

  let(:offer_with_document) { subject.new(opportunity, sample_offer_text_key, recommended_option_config, "static/bayerische_unfall_bedingungen.pdf").call }
  let(:dummy_pdf) { double("pdf") }

  def plan_conf(ident, offer_option_type=:top_cover, is_recommended=false)
    {
      plan_ident:        ident,
      offer_option_type: offer_option_type,
      is_recommended:    is_recommended
    }
  end

  before do
    allow(recommended_plan).to receive(:coverages).and_return(coverage_features)
    allow(opportunity).to receive(:coverage_features).and_return(coverage_features)
    allow(PdfGenerator::Generator).to receive(:pdf_from_assets).and_return(dummy_pdf)
    allow_any_instance_of(Offer).to receive_message_chain("documents.new").with(document_type_id: DocumentType.offer_new.id, asset: dummy_pdf)
    allow_any_instance_of(Offer).to receive_message_chain("documents.create!").with(document_type_id: DocumentType.offer_new.id, asset: dummy_pdf)

    # It's easier to test by customizing the constant. So it's redefined for the scope this context.
    # This is being rolled back in the block to tear down the spec setup (after do ...).
    @configured_feature_idents = described_class::COVERAGE_FEATURES_TO_SHOW
    described_class.send(:remove_const, "COVERAGE_FEATURES_TO_SHOW")
    described_class.const_set("COVERAGE_FEATURES_TO_SHOW", {})
    described_class::COVERAGE_FEATURES_TO_SHOW[category.ident] = coverage_features.map(&:identifier)
    described_class::COVERAGE_FEATURES_TO_SHOW.freeze

    allow(OfferMailer).to receive(:new_product_offer_available)
  end

  after do
    # put the constant back into it's previous state:
    described_class.send(:remove_const, "COVERAGE_FEATURES_TO_SHOW")
    described_class.const_set("COVERAGE_FEATURES_TO_SHOW", @configured_feature_idents)
    described_class::COVERAGE_FEATURES_TO_SHOW.freeze
  end

  context "offer" do
    it "should return an offer" do
      expect(offer).to be_an(Offer)
    end

    it "should know, which coverage features to show" do
      expect(opportunity.coverage_features).not_to be_empty
      expect(offer.displayed_coverage_features).to match_array(coverage_features.map(&:identifier))
    end

    it "should add an offer text" do
      expect(offer.note_to_customer).to eq(note_to_customer)
    end

    it "should connect the offer to the mandate connected to the opportunity" do
      expect(offer.mandate_id).to eq(opportunity.mandate_id)
    end

    it "should persist the offer" do
      expect_any_instance_of(Offer).to receive(:save!)
      offer
    end

    it "should send the offer" do
      expect_any_instance_of(Offer).to receive(:send_offer!)
      offer
    end

    it "attaches a static document to the offer if document is passed" do
      expect(PdfGenerator::Generator).to receive(:pdf_from_assets)
      offer_with_document
    end

    it "should raise an error, if there is no offer text key" do
      expect {
        subject.new(opportunity, "", recommended_option_config)
      }.to raise_error("cannot create the offer text => offer text key is missing!")
    end
  end

  context "offer options" do
    it "should create options" do
      expect(OfferOption).to \
        receive(:create_preconfigured_option!).with(
          plan: recommended_plan,
          offer: Offer,
          option_type: :top_cover_and_price,
          recommended: true,
          product_attrs: {contract_started_at: Time}
        )
      offer
    end

    context "errors" do
      it "should fail, if a plan cannot be found" do
        expect {
          subject.new(
            opportunity,
            sample_offer_text_key,
            non_existing_plan_config
          )
        }.to raise_error("Plan '#{non_existing_plan_config[:plan_ident]}' not found!")
      end

      it "should fail, if a plan is not active" do
        recommended_plan.deactivate!
        intent = subject.new(
          opportunity,
          sample_offer_text_key,
          recommended_option_config
        )
        expect {
          intent.call
        }.to raise_error(match("Plan '#{recommended_plan.ident}' is deactivated!"))
      end
    end
  end

  context "opportunity" do
    it "should assign the opportunity to an admin" do
      offer
      expect(opportunity.admin_id).not_to be_nil
    end

    it "marks the opportunity as in offer phase" do
      offer
      expect(opportunity.offer_phase?).to be_truthy
    end

    it "should mark the opportunity to be automated" do
      expect(opportunity).to receive(:update_attributes!).with(hash_including(is_automated: true))
      offer
    end

    it "should connect the offer to the opportunity" do
      resulted_offer = offer
      expect(opportunity.offer).to eq(resulted_offer)
    end
  end
end
