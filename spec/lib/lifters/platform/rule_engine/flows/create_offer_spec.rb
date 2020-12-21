# frozen_string_literal: true

require "rails_helper"

RSpec.describe Platform::RuleEngineV3::Flows::CreateOffer, :integration do
  subject { described_class }

  let!(:category) { create(:category) }

  let(:coverage_feature_1) { FactoryBot.build(:coverage_feature) }
  let(:coverage_feature_2) { FactoryBot.build(:coverage_feature) }
  let(:coverage_feature_3) { FactoryBot.build(:coverage_feature) }
  let(:coverage_features) { [coverage_feature_1, coverage_feature_2, coverage_feature_3] }

  let(:opportunity) { create(:opportunity, category: category, mandate: mandate) }
  let(:company) { create(:company) }

  let(:mandate) { create(:mandate, :accepted) }

  let(:sample_offer_text_key) { "legal_protection.offer_text" }
  let(:note_to_customer) { I18n.t("automation.#{sample_offer_text_key}", unternehmen: company.name) }

  let(:recommended_plan) { create(:plan, category: category, company: company) }
  let(:valid_plan_2) { create(:plan, category: category, company: company) }
  let(:valid_plan_3) { create(:plan, category: category, company: company) }

  let(:recommended_option_config) do
    plan_conf(recommended_plan.ident, :top_cover_and_price, true, premium_period: :year)
  end
  let(:valid_option_config_2) { plan_conf(valid_plan_2.ident, :top_price) }
  let(:valid_option_config_3) { plan_conf(valid_plan_3.ident) }
  let(:non_existing_plan_config) { plan_conf("unknown_plan_#{rand(100)}") }

  let(:dummy_mail) { n_double("mail") }
  let(:dummy_pdf)  { n_double("pdf") }

  let(:offer) do
    intent = subject.new(
      opportunity,
      sample_offer_text_key,
      recommended_option_config,
      valid_option_config_2,
      valid_option_config_3
    )
    intent.call
  end

  def plan_conf(ident, offer_option_type=:top_cover, is_recommended=false, product_attributes=nil)
    {
      plan_ident:        ident,
      offer_option_type: offer_option_type,
      is_recommended:    is_recommended,
      product_attributes: product_attributes
    }
  end

  before do
    allow(recommended_plan).to receive(:coverages).and_return(coverage_features)
    allow(opportunity).to receive(:coverage_features).and_return(coverage_features)

    # It's easier to test by customizing the constant. So it's redefined for the scope this context.
    # This is being rolled back in the block to tear down the spec setup (after do ...).
    @configured_feature_idents = described_class::COVERAGE_FEATURES_TO_SHOW
    described_class.send(:remove_const, "COVERAGE_FEATURES_TO_SHOW")
    described_class.const_set("COVERAGE_FEATURES_TO_SHOW", {})
    described_class::COVERAGE_FEATURES_TO_SHOW[category.ident] = coverage_features.map(&:identifier)
    described_class::COVERAGE_FEATURES_TO_SHOW.freeze

    allow(PdfGenerator::Generator).to receive(:pdf_by_template).and_return(dummy_pdf)
    allow(PdfGenerator::Generator).to receive(:pdf_from_assets).and_return(dummy_pdf)

    allow_any_instance_of(Offer).to receive_message_chain("documents.build").with(document_type_id: DocumentType.offer_new.id, asset: dummy_pdf)
    allow_any_instance_of(Offer).to receive_message_chain("documents.new").with(document_type_id: DocumentType.offer_new.id, asset: dummy_pdf)
    allow(dummy_mail).to receive(:deliver_now)
    allow(OfferMailer).to receive(:new_product_offer_available).and_return(dummy_mail)
    allow_any_instance_of(Offer).to receive(:vvg_attached_to_offer).and_return(true)
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

    it "should add an offer text also, if the second option config is the recommended option" do
      offer = subject.new(opportunity, sample_offer_text_key, valid_option_config_2, recommended_option_config, valid_option_config_3).call
      expect(offer.note_to_customer).to eq(note_to_customer)
    end

    it "should add an offer text also, if the third option config is the recommended option" do
      offer = subject.new(opportunity, sample_offer_text_key, valid_option_config_2, valid_option_config_3, recommended_option_config).call
      expect(offer.note_to_customer).to eq(note_to_customer)
    end

    it "should connect the offer to the mandate connected to the opportunity" do
      expect(offer.mandate_id).to eq(opportunity.mandate.id)
    end

    it "should persist the offer" do
      offer
      expect(Offer.all.count).to eq(1)
    end

    it "should send the offer" do
      expect_any_instance_of(Offer).to receive(:send_offer!)
      offer
    end

    it "creates the comparison pdf" do
      expect(PdfGenerator::Generator).to receive(:pdf_by_template).with("pdf_generator/comparison_document", anything).and_return(dummy_pdf)
      offer
    end

    it "attaches a static document to the offer if document is passed" do
      expect(PdfGenerator::Generator).to receive(:pdf_from_assets)
      subject.new(opportunity, sample_offer_text_key, recommended_option_config, valid_option_config_2, valid_option_config_3, "doc.pdf").call
    end

    it "should raise an error, if there is no offer text key" do
      expect {
        subject.new(opportunity, "", valid_option_config_2, valid_option_config_3, recommended_option_config)
      }.to raise_error(match("cannot create the offer text => offer text key is missing!"))
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
          product_attrs: {contract_started_at: Time, premium_period: :year}
        )
      expect(OfferOption).to \
        receive(:create_preconfigured_option!).with(
          plan: valid_plan_2,
          offer: Offer,
          option_type: :top_price,
          recommended: false,
          product_attrs: {contract_started_at: Time}
        )
      expect(OfferOption).to \
        receive(:create_preconfigured_option!).with(
          plan: valid_plan_3,
          offer: Offer,
          option_type: :top_cover,
          recommended: false,
          product_attrs: {contract_started_at: Time}
        )
      offer
    end

    context "errors" do
      let(:new_subject) do
        subject.new(
          opportunity,
          sample_offer_text_key,
          valid_option_config_2,
          recommended_option_config,
          valid_option_config_3
        )
      end

      it "fails, if no option is recommended" do
        recommended_option_config[:is_recommended] = false
        expect {
          new_subject
        }.to raise_error(match("needs a recommended option"))
      end

      it "fails, if more than one option is recommended" do
        valid_option_config_3[:is_recommended] = true
        expect {
          new_subject
        }.to raise_error(match("only one option may be recommended"))
      end

      it "should fail, if there is a duplicated plan ident in the configs" do
        valid_option_config_3[:plan_ident] = valid_option_config_2[:plan_ident]
        expect {
          new_subject
        }.to raise_error(match("cannot offer the same plan twice: #{valid_option_config_3[:plan_ident]}"))
      end

      it "should fail, if a plan cannot be found" do
        intent = subject.new(
          opportunity,
          sample_offer_text_key,
          valid_option_config_2,
          recommended_option_config,
          non_existing_plan_config
        )
        expect {
          intent.call
        }.to raise_error(match("Plan '#{non_existing_plan_config[:plan_ident]}' not found!"))
      end

      it "should fail, if a plan is not active" do
        valid_plan_3.deactivate!
        expect {
          new_subject.call
        }.to raise_error(match("Plan '#{valid_plan_3.ident}' is deactivated!"))
      end

      it "should fail, if an Opportunity not in the 'created' state" do
        opportunity.update!(state: "initiation_phase")

        expect {
          new_subject.call
        }.to raise_error(match("Opportunity ##{opportunity.id} is not in the 'created' state"))
      end
    end
  end

  context "opportunity" do
    it "should assing the opportunity to an admin" do
      offer
      expect(opportunity.admin_id).not_to be_nil
    end

    it "marks the opportunity as in offer phase" do
      offer
      expect(opportunity).to be_offer_phase
    end

    it "should assing the opportunity to an admin and moves it to offer phase" do
      resulted_offer = offer
      expect(opportunity.admin_id).not_to be_nil
      expect(opportunity).to be_offer_phase
      expect(opportunity.offer).to eq(resulted_offer)
    end

    it "should mark the opportunity to be automated" do
      expect(opportunity).to receive(:update!).with(hash_including(is_automated: true))
      offer
    end

    it "should connect the offer to the opportunity" do
      resulted_offer = offer
      expect(opportunity.offer).to eq(resulted_offer)
    end

    context "with old product" do
      it "should attach an old product of the same category, if present" do
        old_product = create(:product, category: category, mandate: mandate)
        expect(offer.opportunity.old_product).to eq(old_product)
      end

      it "should attach an old combo product, if the same category is included" do
        combo_category = create(:combo_category, included_category_ids: [category.id])
        old_product = create(:product, category: combo_category, mandate: mandate)
        expect(offer.opportunity.old_product).to eq(old_product)
      end

      it "should fail, if more than one old product is found" do
        create(:product, category: category, mandate: mandate)
        create(:product, category: category, mandate: mandate)
        expect {
          offer
        }.to raise_error(Platform::RuleEngineV3::Flows::CreateOfferError)
      end
    end
  end
end
