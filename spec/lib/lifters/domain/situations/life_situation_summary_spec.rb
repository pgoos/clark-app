# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Situations::LifeSituationSummary do
  subject { described_class.new(mandate) }

  let(:mandate) { instance_double(Mandate) }
  let(:dummy_demand_check) { instance_double(Questionnaire::Response) }
  let(:demand_check_summary_methods) do
    %i[
      yearly_gross_income
      family
      number_of_kids
      job
      job_title
      estate
    ]
  end

  before do
    allow(dummy_demand_check).to receive(:extract_normalized_answer)
    allow(Domain::DemandCheck::DemandCheckHelper).to receive(:latest_demand_check)
      .with(mandate)
      .and_return(dummy_demand_check)

    demand_check_summary_methods.except(:yearly_gross_income).each do |method|
      allow_any_instance_of(Domain::Situations::DemandCheckSituation)
        .to receive(method)
        .and_return("#{method} - value")
    end

    allow_any_instance_of(Domain::Situations::DemandCheckSituation)
      .to receive(:yearly_gross_income)
      .and_return(ValueTypes::Money.new(100, "EUR"))
  end

  context "without data" do
    before do
      allow_any_instance_of(Domain::Situations::DemandCheckSituation)
        .to receive(:demand_check?)
        .and_return(false)
    end

    it "should be empty, if there is no data" do
      expect(subject.empty?).to eq(true)
    end

    it "should have no topics" do
      called = false
      subject.topics do |_,_|
        called = true
      end
      expect(called).to eq(false)
    end
  end

  context "with demand check data" do
    before do
      allow_any_instance_of(Domain::Situations::DemandCheckSituation)
        .to receive(:demand_check?)
        .and_return(true)
    end

    it "should not be empty, if there is demand check data" do
      expect(subject.empty?).to eq(false)
    end

    # summary keys:
    %i[
      yearly_gross_income
      family_status
      amount_children
      job
      accommodation
    ].each do |key|
      it "has the defined summary topic #{key}" do
        has_topic = false
        subject.topics do |topic, topic_value|
          has_topic ||= topic == key && !topic_value.nil?
        end
        expect(has_topic).to eq(true)
      end
    end
  end
end
