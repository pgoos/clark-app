# frozen_string_literal: true

require "rails_helper"

RSpec.describe Customer::Api::V5::Surveys, :integration, type: :request do
  let(:customer) { create(:customer, :self_service) }

  describe "POST /nps" do
    let(:params) { { "nps" => { "score" => 10 } } }

    context "when user is not logged in" do
      it "returns 401" do
        json_post_v5 "/api/customer/surveys/nps", params

        expect(response.status).to be(401)
      end
    end

    shared_examples "a valid request" do
      context "when user is logged in" do
        before { login_customer(customer, scope: :user) }

        it "does not return 401" do
          json_post_v5 "/api/customer/surveys/nps", params

          expect(response.status).to be(201)
        end

        it "creates a new nps" do
          expect {
            json_post_v5 "/api/customer/surveys/nps", params
          }.to change(NPS, :count).by(1).and change(NPSInteraction, :count).by(1)
        end

        context "when params are invalid" do
          it "returns 422" do
            [-1, 11].each do |score|
              json_post_v5 "/api/customer/surveys/nps", { "nps" => { "score" => score } }

              expect(response.status).to be(422)
            end
          end
        end

        context "when surveys is refused" do
          let(:params) { { nps: { refused: true } } }

          it "creates a new nps" do
            nps_count = NPS.count
            nps_interaction_count = NPSInteraction.count

            json_post_v5 "/api/customer/surveys/nps", params

            expect(NPS.count).to be(nps_count)
            expect(NPSInteraction.count).to be(nps_interaction_count + 1)
          end
        end
      end
    end

    context "when nps cycle is opened" do
      before { create(:nps_cycle, :open, end_at: Time.zone.now + 7.days) }

      it_behaves_like "a valid request"
    end

    context "when nps cycle is closing" do
      before { create(:nps_cycle, :closing, end_at: Time.zone.now + 7.days) }

      it_behaves_like "a valid request"
    end
  end

  describe "PATCH /nps/:id" do
    let(:interaction) { create(:nps_interaction, mandate_id: customer.id) }
    let(:nps) { interaction.nps }
    let(:params) { { "nps" => { "comment" => "Super cool app" } } }

    context "when user is not logged in" do
      it "returns 401" do
        json_patch_v5 "/api/customer/surveys/nps/#{interaction.id}", params

        expect(response.status).to be(401)
      end
    end

    context "when user is logged in" do
      before { login_customer(customer, scope: :user) }

      it "does not return 401" do
        json_patch_v5 "/api/customer/surveys/nps/#{interaction.id}", params

        expect(response.status).to be(200)
        expect(response.status).not_to be(401)
      end

      it "updates existing nps interaction" do
        json_patch_v5 "/api/customer/surveys/nps/#{interaction.id}", params

        nps.reload

        expect(nps.comment).to eq("Super cool app")
      end
    end

    context "when mandate does not own the NPS" do
      let(:interaction) { create(:nps_interaction, mandate_id: customer.id) }
      let(:another_customer) { create(:customer, :self_service) }

      before { login_customer(another_customer, scope: :user) }

      it "returns 404" do
        json_patch_v5 "/api/customer/surveys/nps/#{interaction.id}", params

        expect(response.status).to be(404)
      end
    end
  end
end
