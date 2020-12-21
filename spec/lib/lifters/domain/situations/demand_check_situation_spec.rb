# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Situations::DemandCheckSituation do
  subject { subject_class.new(dc_response) }

  let(:subject_class) do
    Class.new do
      include Domain::Situations::DemandCheckSituation

      def initialize(response)
        self.demand_check_response = response
      end

      def use_getter
        demand_check_response
      end
    end
  end
  let(:dc_response) { instance_double(Questionnaire::Response) }

  before do
    allow(dc_response).to receive(:extract_normalized_answer)
  end

  it "should should provide a setter for the dc response" do
    expect(subject.instance_variable_get(:@demand_check_response)).to eq(dc_response)
  end

  it "should expose a method to access the response" do
    expect(subject.use_getter).to eq(dc_response)
  end

  it "should know, if there's a response" do
    expect(subject.demand_check?).to eq(true)
  end

  it "should know, if there's no response" do
    subject_no_response = subject_class.new(nil)
    expect(subject_no_response.demand_check?).to eq(false)
  end

  context "method visibility" do
    let(:sample_class) { Class.new { include Domain::Situations::DemandCheckSituation } }

    it "should not expose the getter to the response to the public interface" do
      expect(sample_class.public_instance_methods).not_to include(:demand_check_response)
    end

    it "should not expose the setter to the response to the public interface" do
      expect(sample_class.public_instance_methods).not_to include(:demand_check_response=)
    end
  end

  context "provide demand check question identifiers as accessor methods" do
    let(:fake_responses) do
      prepared_for_hash = described_class::QUESTION_IDENTS.map do |quest_ident|
        [quest_ident, "#{quest_ident}-#{rand(100)}"]
      end
      prepared_for_hash.to_h
    end

    before do
      described_class::QUESTION_IDENTS.each do |quest_ident|
        allow(dc_response).to receive(:extract_normalized_answer)
          .with(quest_ident).and_return(fake_responses[quest_ident])
      end
    end

    described_class::DEMAND_METHODS.each do |method_name|
      it "should respond to #{method_name}" do
        expect(subject).to respond_to(method_name)
      end

      it "should return the answer value for #{method_name}" do
        expect(subject.send(method_name)).to eq(fake_responses[:"demand_#{method_name}"])
      end

      it "should return empty strings, if the response is nil" do
        subject_no_response = subject_class.new(nil)
        expect(subject_no_response.send(method_name)).to eq("")
      end
    end
  end

  describe "yearly gross income" do
    let(:annual_salary) { (30_000 + rand(20_000)).to_s }

    context "in cents" do
      it "should calculate the gross income in cents, if the response is present" do
        allow(dc_response).to receive(:extract_normalized_answer)
          .with(:demand_annual_salary).and_return(annual_salary)
        expect(subject.yearly_gross_income_in_cents).to eq(annual_salary.to_i * 100)
      end

      it "should be 0, if the answer is blank" do
        allow(dc_response).to receive(:extract_normalized_answer)
          .with(:demand_annual_salary).and_return("")
        expect(subject.yearly_gross_income_in_cents).to eq(0)
      end
    end

    context "as value type" do
      it "should calculate the gross income in cents, if the response is present" do
        allow(dc_response).to receive(:extract_normalized_answer)
          .with(:demand_annual_salary).and_return(annual_salary)
        expected = ValueTypes::Money.new(annual_salary, "EUR").to_monetized
        expect(subject.yearly_gross_income.to_monetized).to eq(expected)
      end

      it "should be 0, if the answer is blank" do
        allow(dc_response).to receive(:extract_normalized_answer)
          .with(:demand_annual_salary).and_return("")
        expected = ValueTypes::Money.new(0, "EUR").to_monetized
        expect(subject.yearly_gross_income.to_monetized).to eq(expected)
      end
    end
  end
end
