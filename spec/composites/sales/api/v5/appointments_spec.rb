# frozen_string_literal: true

require "rails_helper"

describe ::Sales::Api::V5::Appointments, :integration, type: :request do
  describe "POST /api/sales/.current/appointments" do
    let(:starts_at) { Time.zone.parse("12/12/2050") }
    let(:ends_at) { Time.zone.parse("12/12/2050") }

    context "when mandatory parameters are passed in" do
      let(:customer) { create(:customer, :prospect) }
      let(:contact) { { phone: "+49 176 55310475", firstName: "John", lastName: "Doe" } }
      let(:opportunity) { create(:opportunity, mandate_id: customer.id) }
      let(:category) { create(:category) }
      let(:params) do
        {
          appointment: {
            startsAt: starts_at,
            endsAt: ends_at,
            contactModality: "phone",
            topic: {
              id: opportunity.id,
              type: Opportunity.name
            },
            contact: contact,
            strategy: {
              name: nil,
              params: {}
            }
          }
        }
      end

      context "when customer has logged in" do
        context "when topic is passed in" do
          it "schedules appointment" do
            login_customer(customer, scope: :lead)
            json_post_v5 "/api/sales/.current/appointments", params

            expect(response.status).to eq 201
            expect(
              Appointment.exists?(
                starts: starts_at,
                ends: ends_at,
                method_of_contact: "phone",
                call_type: "phone",
                mandate_id: customer.id,
                appointable: opportunity
              )
            ).to be_truthy
          end
        end

        context "when 'force-create' strategy is passed in" do
          let(:source_description) { "Summer Campaign" }
          let(:sales_campaign) { create(:sales_campaign) }
          let(:params_with_strategy) do
            {
              appointment: {
                startsAt: starts_at,
                endsAt: ends_at,
                contactModality: "phone",
                topic: {
                  id: nil,
                  type: Opportunity.name
                },
                contact: contact,
                strategy: {
                  name: "force-create",
                  params: {
                    categoryId: category.id,
                    salesCampaignId: sales_campaign.id,
                    sourceDescription: source_description
                  }
                }
              }
            }
          end

          it "creates correct Opportunity and schedule appointment with it" do
            login_customer(customer, scope: :lead)
            json_post_v5 "/api/sales/.current/appointments", params_with_strategy
            expected_contact = contact.transform_keys { |key| key.to_s.underscore }
            appointment = Appointment.find_by(
              starts: starts_at,
              ends: ends_at,
              method_of_contact: "phone",
              call_type: "phone",
              mandate_id: customer.id,
            )

            expect(response.status).to eq 201
            expect(appointment).to be_truthy
            expect(appointment.appointable.category_id).to eq(category.id)
            expect(appointment.appointable.sales_campaign).to eq(sales_campaign)
            expect(appointment.appointable.source_description).to eq(source_description)
            expect(appointment.contact).to eq(expected_contact)
          end
        end

        context "when passed in opportunity does not belong to customer" do
          it "returns 404 with error message" do
            login_customer(customer, scope: :lead)
            new_params = params.clone
            new_params[:appointment][:topic][:id] = 999
            json_post_v5 "/api/sales/.current/appointments", new_params

            expect(response.status).to eq 404
            error_message = JSON.parse(response.body)["errors"][0]["title"]
            expect(error_message).to eq("ungültiger Wert")
          end
        end

        context "when try to schedule duplicate appointment" do
          it "returns 422" do
            login_customer(customer, scope: :lead)
            json_post_v5 "/api/sales/.current/appointments", params
            json_post_v5 "/api/sales/.current/appointments", params

            expect(response.status).to eq 422
          end
        end
      end

      context "when customer hasn't logged in" do
        it "returns 401 Unauthorized" do
          json_post_v5 "/api/sales/.current/appointments", params

          expect(response.status).to eq 401
        end
      end
    end
  end
end
