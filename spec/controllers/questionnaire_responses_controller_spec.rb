# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuestionnaireResponsesController, :integration, type: :controller do
  describe "POST #create" do
    subject {
      post :create, params: {questionnaire:          questionnaire,
                             questionnaire_response: response_params,
                             locale:                 "de",
                             format:                 :js}
    }

    let(:questionnaire) { SecureRandom.hex(3) }
    let(:response_params) do
      {
        response_id: SecureRandom.hex(8)
      }
    end

    describe "Questionnaire creation" do
      let(:lead) { create :lead, :with_mandate }

      before do
        request.env["warden"].set_user(lead, scope: :lead)
      end

      context "when questionnaire does not exist" do
        it "creates a new object" do
          expect { subject }.to change { Questionnaire.count }.by(1)
        end
      end

      context "when questionnaire does exist already" do
        let(:questionnaire) { create(:questionnaire).identifier }

        before { questionnaire } # create object in database

        it "uses the existing object" do
          expect { subject }.not_to change { Questionnaire.count }
        end
      end
    end

    describe "Questionnaire::Response creation" do
      context "when customer is signed-in user" do
        let(:user) { create(:user, :with_mandate) }

        before do
          sign_in user
          response_params.delete(:email)
          response_params.delete(:name)
        end

        it "creates a new questionnaire response" do
          expect { subject }.to change { Questionnaire::Response.count }.by(1)
          expect(Questionnaire::Response.last.mandate).to eq(user.mandate)
        end

        context "when name and email are provided" do
          let(:email) { "thilo.typeform@test.clark.de" }

          before do
            response_params.merge!(name:  "first last",
                                   email: email)
          end

          context "when mandate is not created yet" do
            before do
              user.mandate.update_attribute(:state, "in_creation")
              user.mandate.update_attributes(first_name: nil, last_name: nil)
            end

            it "creates a new questionnaire response and updates mandate but not user" do
              expect { subject }.to change { Questionnaire::Response.count }.by(1)

              user.reload
              expect(Questionnaire::Response.last.mandate).to eq(user.mandate)
              expect(user.email).not_to eq(email)
              expect(user.mandate.first_name).to eq("First")
              expect(user.mandate.last_name).to eq("Last")
            end
          end

          context "when mandate is created already" do
            before do
              user.mandate.update_attribute(:state, "created")
              user.mandate.update_attributes(first_name: "Peter", last_name: "Pan")
            end

            it "creates a new questionnaire response but does not update user or mandate" do
              expect { subject }.to change { Questionnaire::Response.count }.by(1)

              user.reload
              expect(Questionnaire::Response.last.mandate).to eq(user.mandate)
              expect(user.email).not_to eq(email)
              expect(user.mandate.first_name).not_to eq("First")
              expect(user.mandate.last_name).not_to eq("Last")
            end
          end
        end
      end

      context "when customer is anonymous lead" do
        let(:lead) { create :lead, :with_mandate }

        before do
          request.env["warden"].set_user(lead, scope: :lead)
        end

        it "creates a new questionnaire response" do
          expect { subject }.to change { Questionnaire::Response.count }.by(1)
          expect(Questionnaire::Response.last.mandate).to eq(lead.mandate)
        end

        context "when name and email are provided" do
          let(:email) { "thilo.typeform@test.clark.de" }

          before do
            response_params.merge!(name:  "first last",
                                   email: email)
          end

          it "creates a new questionnaire response and updates lead and mandate" do
            expect { subject }.to change { Questionnaire::Response.count }.by(1)

            lead.reload
            expect(Questionnaire::Response.last.mandate).to eq(lead.mandate)
            expect(lead.email).to eq(email)
            expect(lead.mandate.first_name).to eq("First")
            expect(lead.mandate.last_name).to eq("Last")
          end
        end
      end

      context "when there is not lead or user in session" do
        context "when name and email are provided" do
          let(:email) { "thilo.typeform@test.clark.de" }

          before do
            response_params.merge!(name:  "first last",
                                   email: email)
          end

          it "creates a new lead with mandate and questionnaire response" do
            expect { subject }.to change { Questionnaire::Response.count }.by(1)
                                                                          .and change { Lead.count }.by(1)
                                                                                                    .and change { Mandate.count }.by(1)
                                                                                                                                 .and change { request.env["warden"].user(scope: :lead) }.from(Lead.last)
            expect(Questionnaire::Response.last.mandate).to eq(Lead.last.mandate)
          end
        end

        context "when name and email are provided" do
          it "raises an error since we cannot create a mandate without email" do
            # could create an anonymous lead without email here, but imho we should do this more explicitly
            expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
          end
        end
      end
    end
  end
end
