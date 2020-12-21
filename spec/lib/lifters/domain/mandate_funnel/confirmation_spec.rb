# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::MandateFunnel::Confirmation do
  subject { described_class.new(mandate) }

  let(:mandate) { instance_double(Mandate) }
  let(:even_positive_integer) { ((50 * rand).floor + 1) * 2 }
  let(:odd_positive_integer) { even_positive_integer + 1 }

  before do
    create(:feature_switch, key: Features::RECOMMENDATIONS_BEFORE_DEMAND_CHECK)

    Timecop.freeze(Time.zone.now)
    allow(mandate).to receive(:tos_accepted_at=)
    allow(mandate).to receive(:confirmed_at=)
    allow(mandate).to receive(:health_consent_accepted_at=)
    allow(mandate).to receive(:confirming).and_return(true)
    allow(mandate).to receive(:complete).and_return(true)
    allow(mandate).to receive(:recommend_category!)
    allow(mandate).to receive(:wizard_step_performed?).and_return(true)
    allow(mandate).to receive(:info=)
    allow(mandate).to receive(:info).and_return({})
    allow(BusinessEvent).to receive(:audit)
  end

  after do
    Timecop.return
  end

  context "inconsistent mandate funnel steps" do
    it "logs inconsistent mandate funnel steps" do
      allow_any_instance_of(described_class).to \
        receive(:wizard_steps_consistent?).and_return(false)
      allow(mandate).to receive(:info).and_return({})
      allow(mandate).to receive(:id).and_return(1)

      expect(Rails.logger).to receive(:info).with a_string_matching /Inconsistent mandate funnel steps are found/

      subject.perform
    end
  end

  context "simple confirmation" do
    before do
      allow(mandate).to receive(:id).and_return(odd_positive_integer)
    end

    it "should set the terms and conditions accepted time" do
      expect(mandate).to receive(:tos_accepted_at=).with(Time.current)
      subject.perform
    end

    it "should set the confirmation time" do
      expect(mandate).to receive(:confirmed_at=).with(Time.current)
      subject.perform
    end

    it "should set the health consent acceptance time" do
      expect(mandate).to receive(:health_consent_accepted_at=).with(Time.current)
      subject.perform
    end

    it "should return true, if confirming and complete succeed" do
      expect(subject.perform).to be_truthy
    end

    it "should return false, if confirming fails" do
      allow(mandate).to receive(:confirming).and_return(false)
      expect(subject.perform).to be_falsey
    end

    it "should return false, if complete fails" do
      allow(mandate).to receive(:complete).and_return(false)
      expect(subject.perform).to be_falsey
    end

    it "should set info column attributes" do
      info_param = {
        incentive_funnel_consent: true,
        incentive_funnel_condition: true
      }

      expect(mandate).to receive(:info=).with(info_param)
      described_class.new(mandate, info_param).perform
    end
  end

  context "recommendations before demand check" do
    before do
      allow(mandate).to receive(:id).and_return(even_positive_integer)
      Features.activate_feature!(Features::RECOMMENDATIONS_BEFORE_DEMAND_CHECK)
      create(:category_phv)
      create(:bu_category)
    end

    it "should create recommendations, if the mandate id is even" do
      expect(mandate).to receive(:recommend_category!)
      subject.perform
    end

    it "should write a business event indicating the experiment (instant_recommendations)" do
      expect(BusinessEvent).to receive(:audit).with(mandate, "instant_recommendations")
      subject.perform
    end

    it "should not create recommendations, if the mandate id is odd" do
      allow(mandate).to receive(:id).and_return(odd_positive_integer)
      expect(mandate).not_to receive(:recommend_category!)
      subject.perform
    end

    it "should write a business event indicating the default (default_recommendations)" do
      allow(mandate).to receive(:id).and_return(odd_positive_integer)
      expect(BusinessEvent).to receive(:audit).with(mandate, "default_recommendations")
      subject.perform
    end

    it "should not create recommendations, if the feature is switched off" do
      Features.turn_off_feature!(Features::RECOMMENDATIONS_BEFORE_DEMAND_CHECK)
      expect(mandate).not_to receive(:recommend_category!)
      subject.perform
    end

    [
      Category.phv_ident,
      Category.disability_insurance_ident
    ].each do |ident|
      it "should recommend the category #{ident}" do
        category = Category.find_by(ident: ident)
        expect(mandate).to receive(:recommend_category!).with(category)
        subject.perform
      end
    end
  end
end
