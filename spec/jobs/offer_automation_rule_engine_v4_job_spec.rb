# frozen_string_literal: true

require "rails_helper"

RSpec.describe OfferAutomationRuleEngineV4Job do
  let(:positive_integer) { (100 * rand).round + 1 }
  let(:opportunity) { instance_double(Opportunity, id: positive_integer) }
  let(:automation_rule_class_name) do
    # Please note: the static method #name is overridden by the backport shuffle, the class name
    # is only accessible via #to_s
    Domain::OfferGeneration::HouseholdContents::HouseholdOfferFromComparison.to_s
  end
  let(:automation_rule_class) do
    Domain::OfferGeneration::HouseholdContents::HouseholdOfferFromComparison
    # would be similar for residential property...
  end
  let(:expected_metadata) { {"jobs" => [subject.job_id]} }
  let(:admin) { instance_double(Admin) }

  before do
    subject.arguments = [{opportunity_id: positive_integer, rule_class: automation_rule_class_name}]

    allow(Opportunity).to receive(:find).and_return(nil)
    allow(Opportunity).to receive(:find).with(positive_integer).and_return(opportunity)

    allow(RoboAdvisor).to receive_message_chain(:load_advice_admins, :sample).and_return(admin)

    allow(opportunity).to receive(:update_attributes!).and_return({})
    allow(opportunity).to receive(:metadata).and_return({})
    allow(opportunity).to receive(:update_attributes!).with(metadata: expected_metadata)
    allow(opportunity).to receive(:update_attributes!).with(metadata: {})
  end

  it { is_expected.to be_a(ClarkJob) }

  it "should append to the queue 'offer_automations'" do
    expect(subject.queue_name).to eq("offer_automations")
  end

  it "should connect the job to the opportunity, when enqueued" do
    expect(opportunity).to receive(:update_attributes!).with(metadata: expected_metadata)
    subject._run_enqueue_callbacks
  end

  context "execution happens" do
    before do
      allow(opportunity).to receive(:created?).and_return(true)
      allow(opportunity).to receive(:offer_automation_available?).and_return(true)
      allow(opportunity).to receive(:metadata).and_return(expected_metadata)
    end

    it "should execute the automated rule" do
      expect(automation_rule_class).to receive(:run).with([opportunity], admin, true, true).ordered
      expect(opportunity).to receive(:update_attributes!).with(metadata: {}).ordered

      subject.perform(opportunity_id: opportunity.id, rule_class: automation_rule_class_name)
    end

    it "should keep existing metadata" do
      existing_metadata = {"key" => "value"}
      allow(opportunity).to receive(:metadata).and_return(expected_metadata.merge(existing_metadata))

      expect(automation_rule_class).to receive(:run).with([opportunity], admin, true, true).ordered
      expect(opportunity).to receive(:update_attributes!).with(metadata: existing_metadata).ordered

      subject.perform(opportunity_id: opportunity.id, rule_class: automation_rule_class_name)
    end
  end

  context "execution happens with no mandate accepted" do
    before do
      allow(opportunity).to receive(:created?).and_return(true)
      allow(opportunity).to receive(:offer_automation_available?).and_return(false)
    end

    it "should do nothing" do
      expect(automation_rule_class).not_to receive(:run)
      subject.perform(opportunity_id: opportunity.id, rule_class: automation_rule_class_name)
    end
  end

  context "execution happens with an opportunity not in initiation phase" do
    before do
      allow(opportunity).to receive(:created?).and_return(false)
      allow(opportunity).to receive(:offer_automation_available?).and_return(true)
    end

    it "should do nothing" do
      expect(automation_rule_class).not_to receive(:run)
      subject.perform(opportunity_id: opportunity.id, rule_class: automation_rule_class_name)
    end
  end

  context "execution happens, while other job already exists" do
    before do
      allow(opportunity).to receive(:metadata).and_return("jobs" => ["some_job_id"])
      allow(opportunity).to receive(:created?).and_return(true)
      allow(opportunity).to receive(:offer_automation_available?).and_return(true)
    end

    it "should do nothing" do
      expect(automation_rule_class).not_to receive(:run)
      subject.perform(opportunity_id: opportunity.id, rule_class: automation_rule_class_name)
    end
  end
end
