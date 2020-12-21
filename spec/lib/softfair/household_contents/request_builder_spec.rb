# frozen_string_literal: true

require "rails_helper"
require "softfair/household_contents/request_builder"

RSpec.describe Softfair::HouseholdContents::RequestBuilder do
  let(:subject) { described_class }
  let(:mandate) { create(:mandate) }
  let(:questionnaire_response) { create(:questionnaire_response, mandate: mandate) }
  let!(:candidate_context) do
    candidate_context = n_double("candidate_context")
    allow(candidate_context).to receive(:request=).with(anything) do |xml|
      @generated_xml = xml
      xml
    end
    allow(candidate_context).to receive_message_chain(:adapter, :response).and_return(questionnaire_response)
    candidate_context
  end

  before do
    @apartment_size = 50
    @insurance_start_date = "01.01.2017"
    @house_type = "In einem Einfamilienhaus"
    @extra_protections = "Elementarschäden wie Überschwemmung ,Glasbruch"
    @bike_value = "200"
    @previous_claims = "Keine Schäden"
    allow(questionnaire_response).to receive(:answer_for).with(subject::APARTMENT_SIZE_QUESTION).and_return(@apartment_size)
    allow(questionnaire_response).to receive(:answer_for).with(subject::INSURANCE_START_DATE_QUESTION).and_return(@insurance_start_date)
    allow(questionnaire_response).to receive(:answer_for).with(subject::HOUSE_TYPE_QUESTION).and_return(@house_type)
    allow(questionnaire_response).to receive(:answer_for).with(subject::EXTRA_PROTECTION_QUESTION).and_return(@extra_protections)
    allow(questionnaire_response).to receive(:answer_for).with(subject::BIKE_VALUE_QUESTION).and_return(@bike_value)
    allow(questionnaire_response).to receive(:answer_for).with(subject::PREVIOUS_CLAIMS_QUESTION).and_return(@previous_claims)
    @instance = subject.new(candidate_context)

    allow_any_instance_of(Domain::Products::NewContractBegin).to \
      receive(:calculate).and_return(Time.zone.parse(@insurance_start_date))
  end

  context "request params" do
    context "apartment size" do
      it "adds apartment size data to request params" do
        @instance.build_xml
        expect(@instance.instance_variable_get(:@request_params)[:apartment_size]).to eq(@apartment_size)
      end

      it "does not add apartment size to request params if not a number" do
        allow(questionnaire_response).to receive(:answer_for).with(subject::APARTMENT_SIZE_QUESTION).and_return("invalid apartment size")
        @instance.build_xml
        expect(@instance.instance_variable_get(:@request_params)[:apartment_size]).to be_nil
      end

      context "when value is in valid" do
        before do
          @apartment_size = "InvalidNumber"
          allow(questionnaire_response).to receive(:answer_for).with(subject::APARTMENT_SIZE_QUESTION).and_return(@apartment_size)
        end

        it "returns nil" do
          @instance.build_xml
          expect(@instance.instance_variable_get(:@request_params)[:apartment_size]).to eq(nil)
        end
      end
    end

    context "mandate data" do
      it "adds mandate birthdate to request params" do
        @instance.build_xml
        expect(@instance.instance_variable_get(:@request_params)[:birth_date]).to eq(prepare_date(mandate.birthdate))
      end

      it "adds mandate address fields to request params" do
        @instance.build_xml
        expect(@instance.instance_variable_get(:@request_params)[:street_name]).to eq(mandate.street)
        expect(@instance.instance_variable_get(:@request_params)[:house_number]).to eq(mandate.house_number)
        expect(@instance.instance_variable_get(:@request_params)[:zipcode]).to eq(mandate.zipcode)
        expect(@instance.instance_variable_get(:@request_params)[:city]).to eq(mandate.city)
      end
    end

    context "insurance dates" do
      context "valid start date" do
        it "adds insurance start date to request params" do
          @instance.build_xml
          expect(@instance.instance_variable_get(:@request_params)[:insurance_start_date]).to eq("2017-01-01")
        end

        it "defaults insurance end date to one year from start date" do
          @instance.build_xml
          expect(@instance.instance_variable_get(:@request_params)[:insurance_end_date]).to eq("2018-01-01")
        end
      end

      context "invalid start date" do
        before(:each) do
          allow(questionnaire_response).to receive(:answer_for).with(subject::INSURANCE_START_DATE_QUESTION).and_return("invalid date")
        end

        it "defaults start date to a month from now" do
          @instance.build_xml
          default_start_date = Time.zone.parse(@insurance_start_date)
          expect(@instance.instance_variable_get(:@request_params)[:insurance_start_date]).to eq(prepare_date(default_start_date))
          expect(@instance.instance_variable_get(:@request_params)[:insurance_end_date]).to eq(prepare_date(default_start_date + 1.year))
        end
      end
    end

    context "house type" do
      it "adds house type mapping to request params" do
        @instance.build_xml
        expect(@instance.instance_variable_get(:@request_params)[:house_type]).to eq("HREFH")
      end
    end

    context "extra protection" do
      it "adds extra protection (elementary and glass as predefined in question answers) flags according to user answers to request params" do
        @instance.build_xml
        expect(@instance.instance_variable_get(:@request_params)[:elementary_protection]).to be_truthy
        expect(@instance.instance_variable_get(:@request_params)[:inclusive_flood_risk]).to be_truthy
        expect(@instance.instance_variable_get(:@request_params)[:glass_protection]).to be_truthy
        expect(@instance.instance_variable_get(:@request_params)[:bike_theft_protection]).to be_falsey
      end

      context "bike theft" do
        let(:extra_protection) { "Fahrraddiebstahl" }

        before do
          allow(questionnaire_response).to receive(:answer_for).with(subject::EXTRA_PROTECTION_QUESTION).and_return(extra_protection)
        end

        it "adds bike value if bike theft protection is added" do
          @instance.build_xml
          expect(@instance.instance_variable_get(:@request_params)[:bike_theft_protection]).to be_truthy
          expect(@instance.instance_variable_get(:@request_params)[:bike_value]).to eq(@bike_value.to_i)
        end

        it "defaults bike value to 0 if bike theft protection is not added" do
          allow(questionnaire_response).to receive(:answer_for).with(subject::EXTRA_PROTECTION_QUESTION).and_return("")
          @instance.build_xml
          expect(@instance.instance_variable_get(:@request_params)[:bike_theft_protection]).to be_falsey
          expect(@instance.instance_variable_get(:@request_params)[:bike_value]).to eq(0)
        end

        it "transforms to integer" do
          @instance.build_xml
          expect(@instance.instance_variable_get(:@request_params)[:bike_value]).to be_a(Integer)
        end

        it "transforms a formatted number to an integer" do
          @bike_value = "1.200,00"
          allow(questionnaire_response).to receive(:answer_for).with(subject::BIKE_VALUE_QUESTION).and_return(@bike_value)
          @instance.build_xml
          expect(@instance.instance_variable_get(:@request_params)[:bike_value]).to eq(1200)
        end

        it "transforms a formatted number without fractional to an integer" do
          @bike_value = "1.200"
          allow(questionnaire_response).to receive(:answer_for).with(subject::BIKE_VALUE_QUESTION).and_return(@bike_value)
          @instance.build_xml
          expect(@instance.instance_variable_get(:@request_params)[:bike_value]).to eq(1200)
        end

        it "transforms format 1,200.00 number to an integer" do
          @bike_value = "1,200.00"
          allow(questionnaire_response).to receive(:answer_for).with(subject::BIKE_VALUE_QUESTION).and_return(@bike_value)
          @instance.build_xml
          expect(@instance.instance_variable_get(:@request_params)[:bike_value]).to eq(1200)
        end

        it "transforms format 1,200 number to an integer" do
          @bike_value = "1,200"
          allow(questionnaire_response).to receive(:answer_for).with(subject::BIKE_VALUE_QUESTION).and_return(@bike_value)
          @instance.build_xml
          expect(@instance.instance_variable_get(:@request_params)[:bike_value]).to eq(1200)
        end

        it "allow a € currency postfix" do
          @bike_value = "1200 €"
          allow(questionnaire_response).to receive(:answer_for).with(subject::BIKE_VALUE_QUESTION).and_return(@bike_value)
          @instance.build_xml
          expect(@instance.instance_variable_get(:@request_params)[:bike_value]).to eq(1200)
        end

        it "allow a Euro currency postfix" do
          @bike_value = "1200 Euro"
          allow(questionnaire_response).to receive(:answer_for).with(subject::BIKE_VALUE_QUESTION).and_return(@bike_value)
          @instance.build_xml
          expect(@instance.instance_variable_get(:@request_params)[:bike_value]).to eq(1200)
        end

        it "allow a euro currency postfix" do
          @bike_value = "1200 euro"
          allow(questionnaire_response).to receive(:answer_for).with(subject::BIKE_VALUE_QUESTION).and_return(@bike_value)
          @instance.build_xml
          expect(@instance.instance_variable_get(:@request_params)[:bike_value]).to eq(1200)
        end

        it "fails for € as infix" do
          @bike_value = "1€1"
          allow(questionnaire_response).to receive(:answer_for).with(subject::BIKE_VALUE_QUESTION).and_return(@bike_value)
          expect {
            @instance.build_xml
          }.to raise_error("The given value `#{@bike_value}` cannot be parsed!")
        end

        it "fails for Euro as infix" do
          @bike_value = "1Euro1"
          allow(questionnaire_response).to receive(:answer_for).with(subject::BIKE_VALUE_QUESTION).and_return(@bike_value)
          expect {
            @instance.build_xml
          }.to raise_error("The given value `#{@bike_value}` cannot be parsed!")
        end

        it "allow a € currency prefix" do
          @bike_value = "€ 1200"
          allow(questionnaire_response).to receive(:answer_for).with(subject::BIKE_VALUE_QUESTION).and_return(@bike_value)
          @instance.build_xml
          expect(@instance.instance_variable_get(:@request_params)[:bike_value]).to eq(1200)
        end

        it "allow a Euro currency prefix" do
          @bike_value = "Euro 1200"
          allow(questionnaire_response).to receive(:answer_for).with(subject::BIKE_VALUE_QUESTION).and_return(@bike_value)
          @instance.build_xml
          expect(@instance.instance_variable_get(:@request_params)[:bike_value]).to eq(1200)
        end

        it "allow a euro currency prefix" do
          @bike_value = "euro 1200"
          allow(questionnaire_response).to receive(:answer_for).with(subject::BIKE_VALUE_QUESTION).and_return(@bike_value)
          @instance.build_xml
          expect(@instance.instance_variable_get(:@request_params)[:bike_value]).to eq(1200)
        end

        it "fails for values we cannot parse as integer" do
          @bike_value = "not a number"
          allow(questionnaire_response).to receive(:answer_for).with(subject::BIKE_VALUE_QUESTION).and_return(@bike_value)
          expect {
            @instance.build_xml
          }.to raise_error("The given value `#{@bike_value}` cannot be parsed!")
        end
      end
    end

    context "previous claims" do
      it "adds 0 claims and false to previous claims flag if user has no previous claims" do
        @instance.build_xml
        expect(@instance.instance_variable_get(:@request_params)[:has_claims]).to be_falsey
        expect(@instance.instance_variable_get(:@request_params)[:number_of_claims]).to eq(0)
      end

      it "adds 1 claim and true to previous claims flag if user declared he has a previous claim" do
        previous_claims = "1 Schaden"
        allow(questionnaire_response).to receive(:answer_for).with(subject::PREVIOUS_CLAIMS_QUESTION).and_return(previous_claims)
        @instance.build_xml
        expect(@instance.instance_variable_get(:@request_params)[:has_claims]).to be_truthy
        expect(@instance.instance_variable_get(:@request_params)[:number_of_claims]).to eq(1)
      end
    end
  end

  context "xml soap request" do
    it "generates a valid soap request" do
      mandate.birthdate = "1996-12-06"
      sample_xml = File.open("#{FIXTURE_DIR}/household/valid_request.xml")
      sample_data = Hash.from_xml(sample_xml)
      soap_request = @instance.build_xml
      hash_soap_request = Hash.from_xml(soap_request)
      expect(hash_soap_request["Envelope"]["Body"]["GetHrErgebnis"]["objHrData"])
        .to eq(sample_data["Envelope"]["Body"]["GetHrErgebnis"]["objHrData"])
    end
  end

  private

  def prepare_date(date)
    date.strftime("%Y-%m-%d")
  end
end
