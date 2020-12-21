# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::OfferGeneration::Disability::DisabilityCandidateContext do
  subject { described_class.new(opportunity, adapter, override_params) }

  let(:response) { instance_double(Questionnaire::Response) }
  let(:opportunity) { instance_double(Opportunity, source: response, mandate: mandate) }
  let(:mandate) { instance_double(Mandate) }
  let(:adapter_class) { Domain::OfferGeneration::Disability::DisabilityQuestionnaireAdapter }
  let(:adapter) { instance_double(adapter_class) }
  let(:override_params) { {"age" => 65, "pension" => 1500} }

  context "build from opportunity" do
    before do
      allow(adapter_class).to receive(:new).with(response).and_return(adapter)
    end

    it "creates a #{described_class}" do
      expect(described_class.from_opportunity(opportunity)).to be_a(described_class)
    end

    it "injects the opportunity" do
      expect(described_class).to receive(:new).with(opportunity, any_args)
      described_class.from_opportunity(opportunity)
    end

    it "injects the adapter" do
      expect(described_class).to receive(:new).with(opportunity, adapter, any_args)
      described_class.from_opportunity(opportunity)
    end

    it "injects the override args" do
      expect(described_class).to receive(:new).with(opportunity, adapter, override_params)
      described_class.from_opportunity(opportunity, override_params)
    end
  end

  context "questionnaire adapter delegation" do
    %i[
      subordinate_staff_count
      team_lead?
      smoker?
      employment
      professional_status
      professional_education_grade
      office_work_percentage
      gross_income
    ].each do |delegate_method|
      it "delegates :#{delegate_method}" do
        expect(adapter).to receive(delegate_method)
        subject.send(delegate_method)
      end
    end
  end

  context "override questionnaire values" do

    it "may override the smoker value" do
      override_params[:smoker] = true
      expect(subject).to be_smoker
    end

    it "may override the occupation value" do
      expected_occupation = "Other Occupation"
      override_params[:occupation] = expected_occupation
      expect(subject.employment).to eq(expected_occupation)
    end

    it "may override the professional status value" do
      expected_status = "Other Status"
      override_params[:professionalstatus] = expected_status
      expect(subject.professional_status).to eq(expected_status)
    end

    it "may override the professional education grade value" do
      expected_edu_grade = "Other Grade"
      override_params[:professionaleducationgrade] = expected_edu_grade
      expect(subject.professional_education_grade).to eq(expected_edu_grade)
    end

    it "may override the income value" do
      expected_income = 12345
      override_params[:income] = expected_income
      expect(subject.gross_income).to eq(expected_income)
    end

    it "may override the teamlead value" do
      override_params[:teamlead] = true
      expect(subject).to be_team_lead
    end

    it "may override the subordinate staff count" do
      expected_staff_count = 10
      override_params[:subordinatestaffcount] = expected_staff_count
      expect(subject.subordinate_staff_count).to eq(expected_staff_count)
    end

    it "may override the office percentage" do
      percentage = 10
      override_params[:officepercentage] = percentage
      expect(subject.office_work_percentage).to eq(percentage)
    end
  end

  context "mandate delegation" do
    %i[
      first_name
      last_name
      gender
      birthdate
      street
      house_number
      zipcode
      city
      country_code
    ].each do |delegate_method|
      it "delegates :#{delegate_method}" do
        expect(mandate).to receive(delegate_method)
        subject.send(delegate_method)
      end
    end
  end

  context "accessors" do
    def sample_xml
      <<~EOX
        <?xml version="1.0" encoding="utf-8"?>
        <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
                       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                       xmlns:xsd="http://www.w3.org/2001/XMLSchema">
        </soap:Envelope>
      EOX
    end

    it "gives access to the opportunity" do
      expect(subject.opportunity).to eq(opportunity)
    end

    it "gives access to the override params" do
      expect(described_class.new(opportunity, adapter, override_params).override_params)
        .to eq(override_params)
    end

    it "can set the request" do
      subject.request = sample_xml
      expect(subject.request).to eq(sample_xml)
    end

    it "can set the response" do
      subject.response = sample_xml
      expect(subject.response).to eq(sample_xml)
    end

    it "can set the comparison" do
      comparison = instance_double(InsuranceComparison::DisabilityComparison, persisted?: true)
      subject.persisted_comparison = comparison
      expect(subject.persisted_comparison).to eq(comparison)
    end
  end
end
