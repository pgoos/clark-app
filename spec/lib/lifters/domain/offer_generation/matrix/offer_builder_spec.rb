# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::OfferGeneration::Matrix::OfferBuilder do
  subject { described_class.new(offer_rule: offer_rule, opportunity: opportunity) }

  let(:offer_rule) { build_stubbed(:offer_rule) }
  let(:opportunity) { build_stubbed(:opportunity) }
  let(:admin) { build_stubbed(:admin) }
  let(:now) { Time.zone.parse("Thu, 07 Jun 2018 12:00:00 CEST +02:00") }
  let(:tomorrow_noon) { Time.zone.tomorrow.noon }
  let(:contract_begin) do
    n_instance_double(
      Domain::Products::NewContractBegin,
      "contract begin date",
      calculate: tomorrow_noon
    )
  end
  let(:i18resolve) { proc { |key| I18n.t("activerecord.errors.models.offer.attributes.#{key}") } }
  let(:errors_for) do
    proc do |key|
      offer = subject.new_offer
      offer.valid?
      offer.errors[key].first
    end
  end

  locale = I18n.locale
  before do
    Timecop.freeze(now)
    I18n.locale = :de
    allow(offer_rule).to receive(:plan_idents).and_return([])
    allow(offer_rule).to receive(:displayed_coverage_features).and_return([])
    allow(offer_rule).to receive(:note_to_customer).and_return("")
    allow_any_instance_of(Domain::OfferGeneration::Util::BuildComparisonDoc)
      .to receive(:build_comparison_doc)
    allow(RoboAdvisor).to receive(:load_advice_admins).and_return([admin])
  end

  after do
    Timecop.return
    I18n.locale = locale
  end

  context "when it checks to be permitted to create offers" do
    before do
      allow(Features).to receive(:active?).with(Features::OFFER_AUTOMATION_BY_RULE_MATRIX).and_return(true)
    end

    it "should not be permitted, if the opportunity is nil" do
      expect(described_class.creation_permitted?(opportunity: nil)).to eq(false)
    end

    it "should be permitted, if the opportunity state is 'created'" do
      accepted = build_stubbed(:opportunity, state: "created", admin_id: nil)
      expect(described_class.creation_permitted?(opportunity: accepted)).to eq(true)
    end

    %w[offer_phase completed lost].each do |state|
      it "should not be permitted, if the opportunity state is #{state}" do
        rejected = build_stubbed(:opportunity, state: state)
        expect(described_class.creation_permitted?(opportunity: rejected)).to eq(false)
      end
    end

    it "should be rejected, if the feature is globally switched off" do
      new_opportunity = build_stubbed(:opportunity, state: "created")
      allow(Features).to receive(:active?).with(Features::OFFER_AUTOMATION_BY_RULE_MATRIX).and_return(false)
      expect(described_class.creation_permitted?(opportunity: new_opportunity)).to eq(false)
    end

    it "should be rejected for opportunity, assigned to the consultant" do
      new_opportunity = build_stubbed(:opportunity, state: "initiation_phase", admin_id: 1)
      allow(Features).to receive(:active?).with(Features::OFFER_AUTOMATION_BY_RULE_MATRIX).and_return(false)
      expect(described_class.creation_permitted?(opportunity: new_opportunity)).to eq(false)
    end

    it "should be rejected for the opportunity state is 'initiation_phase'" do
      accepted = build_stubbed(:opportunity, state: "initiation_phase")
      expect(described_class.creation_permitted?(opportunity: accepted)).to eq(false)
    end
  end

  context "when it builds the coverages" do
    it "should not be valid, if the coverages found are not enough" do
      expect(errors_for.(:displayed_coverage_features)).to eq(i18resolve.("displayed_coverage_features.wrong_amount"))
    end

    it "should be valid, if enough coverages are found" do
      allow(offer_rule).to receive(:displayed_coverage_features).and_return(%w[one two three])
      expect(errors_for.(:displayed_coverage_features)).to be_nil
    end

    it "should be valid, if more than 10 coverages are found" do
      allow(offer_rule).to receive(:displayed_coverage_features).and_return((1..11).to_a.map(&:to_s))
      expect(errors_for.(:displayed_coverage_features)).to be_nil
    end
  end

  context "when it builds offer options" do
    let(:plan_ident1) { "plan1" }
    let(:plan_ident2) { "plan2" }
    let(:plan_ident3) { "plan3" }
    let(:stub_build_offer_option) do
      proc do |plan_ident, recommended=false|
        attributes = {
          plan_ident: plan_ident, contract_begin: tomorrow_noon, is_recommended: recommended, option_type: nil
        }
        option = build(:offer_option)
        allow_any_instance_of(Domain::OfferGeneration::Util::BuildOfferOption)
          .to receive(:build_offer_option)
          .with(attributes)
          .and_return(option)
      end
    end

    before do
      allow(offer_rule).to receive(:displayed_coverage_features).and_return(%w[one two three])
      allow(offer_rule).to receive(:plan_idents).and_return([plan_ident1, plan_ident2, plan_ident3])
      stub_build_offer_option.(plan_ident1, true)
      stub_build_offer_option.(plan_ident2)
      stub_build_offer_option.(plan_ident3)
      allow(Domain::Products::NewContractBegin)
        .to receive(:from_opportunity)
        .with(opportunity)
        .and_return(contract_begin)
    end

    it "should build three offer options" do
      expect(subject.new_offer.offer_options.to_a.count).to eq(3)
    end
  end

  it "adds a note to the customer" do
    note_to_customer = "The note to the customer..."
    allow(offer_rule).to receive(:note_to_customer).and_return(note_to_customer)
    expect(subject.new_offer.note_to_customer).to eq(note_to_customer)
  end

  it "adds the comparison doc" do
    expect_any_instance_of(Domain::OfferGeneration::Util::BuildComparisonDoc)
      .to receive(:build_comparison_doc)
    subject.new_offer
  end

  it "references the rule that triggered the offer creation" do
    offer = subject.new_offer
    expect(offer.offer_rule).to eq(offer_rule)
  end

  it "adds a robo admin" do
    offer = subject.new_offer
    expect(offer.opportunity.admin).to eq(admin)
  end

  it "defines the opportunity to be automated" do
    offer = subject.new_offer
    expect(offer.opportunity).to be_is_automated
  end
end
