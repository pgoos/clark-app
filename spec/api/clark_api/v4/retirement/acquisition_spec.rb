# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::V4::Retirement::Acquisition, :integration do
  before do
    create :retirement_income_tax, income_tax_percentage: 3083
    create(:retirement_elderly_deductible, deductible_max_amount_cents: 0, deductible_percentage: 0)
    create(:retirement_taxable_share, year: 2052, taxable_share_state_percentage: 10_000)
    create :retirement_income_tax, income_cents: 2_400_000, income_tax_percentage: 1_613
  end

  context "GET api/retirement/acquisition/net_retirement_calculation" do
    context "when valid params present" do
      before { Timecop.freeze(Date.new(2018, 11, 13)) }

      after { Timecop.return }

      it "returns ok response" do
        json_get_v4 "/api/retirement/acquisition/net_retirement_calculation",
                    gross_salary: 12_222, date_of_birth: "1990-09-01"
        expect(response.status).to eq(200)
      end

      it "returns values in expected format" do
        json_get_v4 "/api/retirement/acquisition/net_retirement_calculation",
                    gross_salary: 12_222, date_of_birth: "1990-09-01"
        expect(response.status).to eq(200)
        result_from_server = JSON.parse(response.body)

        expect(result_from_server["net_state_income"]).to be_kind_of(Float)
        expect(result_from_server["net_recommended_income"]).to be_kind_of(Float)
      end

      it "returns values as expected" do
        expected_state_income = 1403.33
        expected_recommended_income = 3192.92

        json_get_v4 "/api/retirement/acquisition/net_retirement_calculation",
                    gross_salary: 50_000, date_of_birth: "1985-01-01"
        expect(response.status).to eq(200)
        result_from_server = JSON.parse(response.body)
        expect(result_from_server["net_state_income"]).to eq(expected_state_income)
        expect(result_from_server["net_recommended_income"]).to eq(expected_recommended_income)
      end
    end

    context "when params missing" do
      it "returns 400 error" do
        json_get_v4 "/api/retirement/acquisition/net_retirement_calculation"
        expect(response.status).to eq(400)
        expected_error_message = I18n.t("grape.errors.messages.presence")
        error_message_received = JSON.parse(response.body)
        expect(error_message_received["errors"]["api"]["gross_salary"]).to include(expected_error_message)
        expect(error_message_received["errors"]["api"]["date_of_birth"]).to include(expected_error_message)
      end

      context "when gross salary is missing" do
        it "returns error 400 indicating salary is missing" do
          json_get_v4 "/api/retirement/acquisition/net_retirement_calculation", date_of_birth: "01/09/1990"
          expected_error_message = I18n.t("grape.errors.messages.presence")
          error_message_received = JSON.parse(response.body)
          expect(error_message_received["errors"]["api"]["gross_salary"]).to include(expected_error_message)
        end
      end
    end

    context "when date format is wrong" do
      it "returns 400 error" do
        json_get_v4 "/api/retirement/acquisition/net_retirement_calculation",
                    gross_salary: 12_222, date_of_birth: "01/09/1990"
        expect(response.status).to eq(400)
        expected_error_message = I18n.t("grape.errors.messages.date_wrong_format")
        error_message_received = JSON.parse(response.body)
        expect(error_message_received["errors"]["api"]["date_of_birth"]).to eq(expected_error_message)
      end

      it "returns 400 error when format is %Y.%m.%d" do
        json_get_v4 "/api/retirement/acquisition/net_retirement_calculation",
                    gross_salary: 12_222, date_of_birth: "1990.09.01"
        expect(response.status).to eq(400)
        expected_error_message = I18n.t("grape.errors.messages.date_wrong_format")
        error_message_received = JSON.parse(response.body)
        expect(error_message_received["errors"]["api"]["date_of_birth"]).to eq(expected_error_message)
      end

      it "returns 400 error when format is %m.%d.%Y" do
        json_get_v4 "/api/retirement/acquisition/net_retirement_calculation",
                    gross_salary: 12_222, date_of_birth: "09.21.1990"
        expect(response.status).to eq(400)
        expected_error_message = I18n.t("grape.errors.messages.date_wrong_format")
        error_message_received = JSON.parse(response.body)
        expect(error_message_received["errors"]["api"]["date_of_birth"]).to eq(expected_error_message)
      end
    end

    context "when salary is a negative number" do
      it "returns 400 error" do
        json_get_v4 "/api/retirement/acquisition/net_retirement_calculation",
                    gross_salary: -1, date_of_birth: "1990-09-01"
        expect(response.status).to eq(400)
        expected_error_message = I18n.t("grape.errors.messages.salary_value_incorrect")
        error_message_received = JSON.parse(response.body)
        expect(error_message_received["errors"]["api"]["gross_salary"]).to include(expected_error_message)
      end
    end
  end
end
