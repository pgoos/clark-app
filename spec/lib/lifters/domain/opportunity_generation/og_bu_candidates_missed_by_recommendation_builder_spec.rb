# frozen_string_literal: true

require "rails_helper"
require "ostruct"

RSpec.describe Domain::OpportunityGeneration::OgBuCandidatesMissedByRecommendationBuilder do
  # System prerequisites
  let!(:admin) { create(:admin) }

  # Rule metadate
  let(:subject) { described_class }
  let(:expected_name) { "OG_BU_CANDIDATES_MISSED_BY_RECOMMENDATION_BUILDER" }
  let(:limit) {}

  # Situation Specification
  let(:situation_class) { NilClass }
  let(:situation_expectations) { [] }

  # Candidate Specification
  let(:candidate) do
    create(
      :mandate,
      state: "accepted"
    )
  end
  let(:candidates) do
    automatable = OpenStruct.new
    {
      automatable => true
    }
  end

  # Intent to be played
  let(:intent_class) { Platform::RuleEngineV3::Flows::MessageToQuestionnaire }

  before do
    @remembered_ids = described_class::MANDATE_IDS
    described_class.send(:remove_const, :MANDATE_IDS)
    described_class::MANDATE_IDS = [candidate.id]
    described_class::MANDATE_IDS.freeze
  end

  after do
    described_class.send(:remove_const, :MANDATE_IDS)
    described_class::MANDATE_IDS = @remembered_ids
    described_class::MANDATE_IDS.freeze
  end

  context 'name and metadata' do
    it { expect(subject.ident).to eq(expected_name) }
    it { expect(subject.content_key).not_to be_nil }
  end

  context "push i18n" do
    let(:bu) { create(:bu_category) }
    let(:questionnaire) do
      create(
        :questionnaire,
        identifier: Category.disability_insurance_ident,
        category:   bu
      )
    end

    before do
      @current_locale = I18n.locale
      I18n.locale = :de
      bu.update_attributes!(questionnaire: questionnaire)
    end

    after do
      I18n.locale = @current_locale
    end

    it "should have a title" do
      title = I18n.t("transactional_push.og_bu_candidates_missed_by_recommendation_builder.title")
      expect(title).not_to match("translation missing")
    end

    it "should have a clark url" do
      url = I18n.t(
        "transactional_push.og_bu_candidates_missed_by_recommendation_builder.url",
        questionnaire_ident: questionnaire.identifier
      )
      expect(url).to eq("/de/app/questionnaire/#{Category.disability_insurance_ident}")
    end

    it "should have a section" do
      section = I18n.t("transactional_push.og_bu_candidates_missed_by_recommendation_builder.section")
      expect(section).to eq("manager")
    end
  end

  context ".candidates" do
    it { expect(subject.candidates.count).not_to eq(0) }
    it { expect(subject.candidates.first).to be_a(candidate.class) }

    it "does not operate twice on candidates" do
      expect(subject.candidates.count).to eq(described_class::MANDATE_IDS.count)
      create(
        :document,
        documentable:  candidate,
        document_type: DocumentType.og_bu_candidates_missed_by_recommendation_builder
      )
      expect(subject.candidates.count).to eq(described_class::MANDATE_IDS.count - 1)
    end
  end
end
