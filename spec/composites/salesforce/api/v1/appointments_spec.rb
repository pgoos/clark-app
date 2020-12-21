# frozen_string_literal: true

require "rails_helper"

describe Salesforce::Api::V1::Appointments, :integration, type: :request do
  describe ".accept" do
    let(:appointment) { create :appointment }

    let(:params) do
      { appointment: { id: appointment.id } }
    end

    let(:headers) { { "Authorization" => "Token" } }

    describe "POST /api/callbacks/v1/appointments/accept" do
      it "returns 401" do
        post("/api/callbacks/v1/appointments/accept", params: params)

        expect(response.status).to eq 401
      end

      context "authenticated request" do
        before do
          allow(Settings.salesforce).to receive(:integration_command_token).and_return("Token")
        end

        context "when appointment requested" do
          it "accepts appointment" do
            expect(BusinessEvent).to receive(:audit).with(appointment, :accept)
            post("/api/callbacks/v1/appointments/accept", params: params, headers: headers)

            attributes = JSON.parse(response.body)["data"]["attributes"]
            confirmed_appointment = appointment.reload

            expect(response.status).to eq 201
            expect(attributes["state"]).to eq("accepted")
            expect(attributes["state"]).to eq(confirmed_appointment.state)
            expect(attributes["id"]).to eq(confirmed_appointment.id)
          end
        end

        context "when appointment canceled" do
          let(:appointment) { create :appointment, state: "cancelled" }

          it "returns an error" do
            post("/api/callbacks/v1/appointments/accept", params: params, headers: headers)

            response_body = JSON.parse(response.body)

            expect(response.status).to eq 404
            expect(response_body["error"])
              .to eq([I18n.t("composites.sales.constituents.appointments.not_accepted")])
          end
        end

        context "when appointment is already accepted" do
          let(:appointment) { create :appointment, state: "accepted" }

          it "returns 200" do
            expect(BusinessEvent).not_to receive(:audit).with(appointment, :accept)
            post("/api/callbacks/v1/appointments/accept", params: params, headers: headers)

            attributes = JSON.parse(response.body)["data"]["attributes"]
            confirmed_appointment = appointment.reload

            expect(response.status).to eq 200
            expect(attributes["state"]).to eq("accepted")
            expect(attributes["state"]).to eq(confirmed_appointment.state)
            expect(attributes["id"]).to eq(confirmed_appointment.id)
          end
        end
      end
    end

    describe "POST /api/callbacks/v1/appointments/cancel" do
      it "returns 401" do
        post("/api/callbacks/v1/appointments/cancel", params: params)

        expect(response.status).to eq 401
      end

      context "authenticated request" do
        before do
          allow(Settings.salesforce).to receive(:integration_command_token).and_return("Token")
        end

        context "when appointment requested" do
          it "cancel appointment" do
            expect(BusinessEvent).to receive(:audit).with(appointment, :cancel)
            post("/api/callbacks/v1/appointments/cancel", params: params, headers: headers)

            attributes = JSON.parse(response.body)["data"]["attributes"]
            confirmed_appointment = appointment.reload

            expect(response.status).to eq 201
            expect(attributes["state"]).to eq("cancelled")
            expect(attributes["state"]).to eq(confirmed_appointment.state)
            expect(attributes["id"]).to eq(confirmed_appointment.id)
          end
        end

        context "when appointment is already canceled" do
          let(:appointment) { create :appointment, state: "cancelled" }

          it "returns 200" do
            post("/api/callbacks/v1/appointments/cancel", params: params, headers: headers)

            response_body = JSON.parse(response.body)

            attributes = JSON.parse(response.body)["data"]["attributes"]
            confirmed_appointment = appointment.reload

            expect(response.status).to eq 200
            expect(attributes["state"]).to eq("cancelled")
            expect(attributes["state"]).to eq(confirmed_appointment.state)
            expect(attributes["id"]).to eq(confirmed_appointment.id)
          end
        end
      end
    end

    describe "POST /api/callbacks/v1/appointments" do
      let(:starts_at) { Time.zone.parse((DateTime.current + 1.day).to_s) }
      let(:ends_at) { Time.zone.parse((DateTime.current + 1.day + 1.hour).to_s) }

      let(:customer) { create(:customer, :prospect) }
      let(:opportunity) { create(:opportunity, mandate_id: customer.id) }

      let(:params) do
        {
          appointment: {
            customer_id: customer.id,
            starts_at: starts_at,
            ends_at: ends_at,
            contact_modality: "phone",
            topic: {
              id: opportunity.id,
              type: Opportunity.name
            }
          }
        }
      end

      it "returns 401" do
        post("/api/callbacks/v1/appointments", params: params)

        expect(response.status).to eq 401
      end

      context "authenticated request" do
        before do
          allow(Settings.salesforce).to receive(:integration_command_token).and_return("Token")
        end

        context "assigned opportunity" do
          it "increases number of appointments by 1" do
            expect { post("/api/callbacks/v1/appointments", params: params, headers: headers) }
              .to change(::Appointment, :count).by(1)
          end

          it "schedules an appointment and accepts it" do
            post("/api/callbacks/v1/appointments", params: params, headers: headers)

            appointment = Appointment.find_by(
              starts: starts_at.in_time_zone,
              ends: ends_at.in_time_zone,
              method_of_contact: "phone",
              call_type: "phone",
              mandate_id: customer.id
            )

            expect(response.status).to eq 201
            expect(appointment).to be_truthy
            expect(appointment.appointable.category_id).to eq(opportunity.category.id)
            expect(appointment.state).to eq("accepted")
          end
        end

        context "unassigned opportunity" do
          before do
            opportunity.update!(admin_id: nil)
          end

          it "does not increase number of appointments" do
            expect { post("/api/callbacks/v1/appointments", params: params, headers: headers) }
              .to change(::Appointment, :count).by(0)
          end

          it "does not create a new appointment" do
            post("/api/callbacks/v1/appointments", params: params, headers: headers)

            response_body = JSON.parse(response.body)

            appointment = Appointment.find_by(
              starts: starts_at.in_time_zone,
              ends: ends_at.in_time_zone,
              method_of_contact: "phone",
              call_type: "phone",
              mandate_id: customer.id
            )

            expect(response.status).to eq 422
            expect(appointment).to be_nil
            expect(response_body["error"])
              .to include(I18n.t("composites.sales.constituents.appointments.opportunity_not_assigned"))
          end
        end
      end
    end
  end
end
