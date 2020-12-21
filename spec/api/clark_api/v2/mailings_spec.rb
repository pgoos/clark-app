# frozen_string_literal: true

require "rails_helper"

RSpec::Matchers.define_negated_matcher :not_change, :change

RSpec.describe ClarkAPI::V2::Mailings, :integration do
  include AppointmentDateHelpers
  let!(:admin) { create(:gkv_consultants_admin) }

  context "POST /api/mailings/gkv" do
    subject { json_post_v2 "/api/mailings/gkv", params }

    let(:appointment_date) do
      date = Time.zone.tomorrow
      date = date.advance(days: 1) while holiday?(date)
      date
    end
    let(:mandatory_params) do
      {
        email:                 "test@test.de",
        telephone:             "4912312345678",
        appointment_date:      appointment_date.to_s,
        appointment_time:      "10:00",
        zipcode:               "60313",
        insurance_beneficiary: "family",
        profession:            "Astronaut",
        selected_plan_id:      "747",
      }
    end

    let(:optional_params) do
      {
        current_insurance_provider_company_id: "12",
        yearly_salary:               "100000",
        comparison_options_plan_ids: ["1", "2", "3"].to_s
      }
    end

    context "when mandatory parameters are given" do
      let(:params) { mandatory_params }

      it "sends email with form data to Clark employee", skip: true do
        expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(2)

        expect(response.status).to eq(201)

        service_email = ActionMailer::Base.deliveries[-2]
        expect(service_email.to[0]).to eq(Settings.emails.service)
        expect(service_email.reply_to[0]).to eq("test@test.de")
        params.values.each { |value| expect(service_email.body.encoded).to match(value) }
      end
    end

    context "when all possible parameters are given" do
      let(:params) { mandatory_params.merge(optional_params) }

      it "sends email with form data to Clark employee", skip: true  do
        expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(2)

        expect(response.status).to eq(201)

        service_email = ActionMailer::Base.deliveries[-2]
        expect(service_email.to[0]).to eq(Settings.emails.service)
        expect(service_email.reply_to[0]).to eq("test@test.de")

        params.values.each { |value| expect(service_email.body.encoded).to match(value) }
      end
    end

    context "when mandatory params are missing" do
      let(:params) { nil }

      it "does not send an email and returns presence validation errors" do
        expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(0)

        expect(response.status).to eq(400)
        expect(response.body).to match("errors")
        mandatory_params.keys.each { |param| expect(response.body).to match(param.to_s) }
      end
    end

    context "e-mail validation" do
      let(:params) { mandatory_params.merge(optional_params) }

      context "does not send an email when email is invalid" do
        it "missing @" do
          params[:email] = "notemail.com"
          expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(0)

          expect(response.status).to eq(400)
          expect(response.body).to match("errors")
        end
        it "incomplete email" do
          params[:email] = "email@"
          expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(0)

          expect(response.status).to eq(400)
          expect(response.body).to match("errors")
        end
        it "missing email ending" do
          params[:email] = "email@d"
          expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(0)

          expect(response.status).to eq(400)
          expect(response.body).to match("errors")
        end
        it "missing email domain" do
          params[:email] = "email@d."
          expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(0)

          expect(response.status).to eq(400)
          expect(response.body).to match("errors")
        end
      end
    end

    context "e-mail validation" do
      let(:params) { mandatory_params.merge(optional_params) }

      it "send an email when email is valid", skip: true  do
        expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(2)
        expect(response.status).to eq(201)

        service_email = ActionMailer::Base.deliveries[-2]
        expect(service_email.reply_to[0]).to eq("test@test.de")
        expect(service_email.to[0]).to eq(Settings.emails.service)
        expect(service_email.body.encoded).to include("Anfrage GKV")
      end
    end
  end
end
