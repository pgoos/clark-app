# frozen_string_literal: true

require "rails_helper"

describe OpportunityDecorator, type: :decorator do
  subject { opportunity.decorate }

  let(:opportunity) { create(:opportunity) }

  describe "#appointments" do
    let!(:appointments) do
      create_list(:appointment, 2, appointable: opportunity)
    end

    context "when source is Appointment" do
      let(:opportunity) { create(:opportunity, source: appointment) }
      let(:appointment) { create(:appointment) }

      it "returns appointments relation as well as source" do
        expect(subject.appointments).to include appointment
      end
    end

    context "when source isn't Appointment" do
      it "returns only appointments based on the relation" do
        expect(subject.appointments).to match_array(appointments)
      end
    end
  end

  describe "#welcome_call" do
    let(:user_situation) { instance_double(Domain::Situations::UserSituation) }

    before do
      allow(Domain::Situations::UserSituation).to receive(:new).with(opportunity.mandate) { user_situation }
    end

    context "with welcome_call" do
      let(:welcome_call) { { status: :not_attempted, interaction: nil } }

      before { allow(user_situation).to receive(:welcome_call) { welcome_call } }

      it { expect(subject.welcome_call).to eq welcome_call }
    end

    context "without welcome_call" do
      before { allow(user_situation).to receive(:welcome_call).and_return({}) }

      it { expect(subject.welcome_call).to eq({}) }
    end
  end

  describe "#successful_welcome_call?" do
    let(:user_situation) { instance_double(Domain::Situations::UserSituation) }

    before do
      allow(Domain::Situations::UserSituation).to receive(:new).with(opportunity.mandate) { user_situation }
      allow(user_situation).to receive(:welcome_call) { welcome_call }
    end

    context "when status is successful" do
      let(:welcome_call) { { status: :successful, interaction: "interaction" } }

      it { expect(subject).to be_successful_welcome_call }
    end

    context "when status is not successful" do
      let(:welcome_call) { { status: :not_attempted, interaction: nil } }

      it { expect(subject).not_to be_successful_welcome_call }
    end
  end

  describe "#high_margin_consultant" do
    before do
      allow(Opportunity).to receive(:first_consultant_assigned_for_high_margin)
        .with(opportunity.mandate.id) { consultant }
    end

    context "with consultant" do
      let(:consultant) { build_stubbed(:admin) }

      it { expect(subject.high_margin_consultant).to eq consultant }
    end

    context "with no consultant" do
      let(:consultant) { nil }

      it { expect(subject.high_margin_consultant).to be_nil }
    end
  end

  describe "#with_single_offer_option?" do
    context "without offer options" do
      it { expect(subject).not_to be_with_single_offer_option }
    end

    context "with three offer options" do
      let(:opportunity_with_options) { create(:opportunity_with_offer_in_creation) }

      it { expect(opportunity_with_options.decorate).not_to be_with_single_offer_option }
    end

    context "with single offer option" do
      let(:offer_with_single_option) do
        create(
          :offer,
          offer_options: [
            create(:offer_option, recommended: true)
          ]
        )
      end

      let(:opportunity_with_single_option) do
        create(:opportunity, offer: offer_with_single_option)
      end

      it { expect(opportunity_with_single_option.decorate).to be_with_single_offer_option }
    end
  end

  describe "#aoa_data" do
    let!(:admin) { create :admin, access_flags: ["sales_consultation"] }
    let(:bu_category) { create(:category, ident: "3d439696") }
    let(:opportunity) { create(:opportunity, category: bu_category) }
    let(:error_message) { "API AOA error!" }

    let!(:admin1) { create :admin }
    let!(:admin2) { create :admin }
    let!(:admin3) { create :admin }
    let!(:admin4) { create :admin }

    let(:all_active_admin_ids) { Admin.active.map(&:id) }

    let(:aoa_suggested_consultant_ids) { [admin1.id, admin2.id, admin3.id] }

    let(:aoa_data_response) do
      OpenStruct.new(
        errors: [],
        aoa_ranks: Admin.active.where(id: aoa_suggested_consultant_ids).map(&:id)
      )
    end

    let(:aoa_data_response_with_error) do
      OpenStruct.new(
        errors: [error_message],
        aoa_ranks: []
      )
    end

    before do
      allow_any_instance_of(Sales::Constituents::Opportunity::Repositories::AoaSettingsRepository)
        .to receive(:aoa_test_group).and_return("100")
    end

    context "when AOA_BASED_CONSULTANT_ASSIGNMENT Feature is ON" do
      before do
        allow(Features)
          .to receive(:active?)
          .with(Features::API_NOTIFY_PARTNERS)
          .and_return(false)

        allow(Features)
          .to receive(:active?)
          .with(Features::AOA_BASED_CONSULTANT_ASSIGNMENT)
          .and_return(true)
      end

      context "with assigned consultant" do
        it "returns valid data" do
          data = subject.aoa_data

          expect(data[:admins_for_select].map(&:id)).to match_array(all_active_admin_ids)
          expect(data[:response][:aoa_errors]).to eq([])
          expect(data[:response][:aoa_consultant_ids]).to eq([])
          expect(data[:response][:cohort]).to eq("control_group")
        end
      end

      context "with not assigned consultant" do
        before do
          opportunity.update!(admin_id: nil)
        end

        context "aoa response without errors" do
          let(:request_id) { Faker::String.random }
          let(:farady_response) do
            OpenStruct.new(
              body: { allocated_consultants: aoa_suggested_consultant_ids }.to_json,
              env: OpenStruct.new(
                request_headers: { "X-Request-Id" => request_id }
              )
            )
          end
          let(:request) { { available_consultants: [] } }

          before do
            allow_any_instance_of(::Sales::Constituents::Opportunity::Interactors::RequestAoaRanks)
              .to receive(:execute_aoa_request)
              .and_return(farady_response)
          end

          it "returns valid data" do
            expect(BusinessEvent)
              .to receive(:audit)
              .with(
                opportunity, "aoa_requested",
                {
                  request: request,
                  response: { body: farady_response.body, request_uuid: request_id }
                }
              )
            data = subject.aoa_data

            expect(data[:admins_for_select].map(&:id)).to match_array(aoa_suggested_consultant_ids)
            expect(data[:response][:aoa_errors]).to eq([])
            expect(data[:response][:aoa_consultant_ids]).to match_array(aoa_suggested_consultant_ids)
            expect(data[:response][:request_uuid]).to eq(request_id)
            expect(data[:response][:cohort]).to eq("aoa_group")
          end
        end

        context "aoa response with errors" do
          before do
            allow_any_instance_of(::Sales::Constituents::Opportunity::Interactors::BuildAoaData)
              .to receive(:aoa_response)
              .and_return(aoa_data_response_with_error)
          end

          it "returns valid data" do
            data = subject.aoa_data

            expect(data[:admins_for_select].map(&:id)).to match_array(all_active_admin_ids)
            expect(data[:response][:aoa_errors]).to eq([error_message])
            expect(data[:response][:aoa_consultant_ids]).to eq([])
            expect(data[:response][:request_uuid]).to eq(nil)
            expect(data[:response][:cohort]).to eq("control_group")
          end
        end
      end
    end

    context "when AOA_BASED_CONSULTANT_ASSIGNMENT Feature is OFF" do
      before do
        allow(Features)
          .to receive(:active?)
          .with(Features::API_NOTIFY_PARTNERS)
          .and_return(false)

        allow(Features)
          .to receive(:active?)
          .with(Features::AOA_BASED_CONSULTANT_ASSIGNMENT)
          .and_return(false)
      end

      context "with assigned consultant" do
        it "returns valid data" do
          data = subject.aoa_data

          expect(data[:admins_for_select].map(&:id)).to match_array(all_active_admin_ids)
          expect(data[:response][:aoa_errors]).to eq([])
          expect(data[:response][:aoa_consultant_ids]).to eq([])
          expect(data[:response][:request_uuid]).to eq(nil)
          expect(data[:response][:cohort]).to eq("control_group")
        end
      end

      context "with not assigned consultant" do
        before do
          opportunity.update!(admin_id: nil)
        end

        it "returns valid data" do
          data = subject.aoa_data

          expect(data[:admins_for_select].map(&:id)).to match_array(all_active_admin_ids)
          expect(data[:response][:aoa_errors]).to eq([])
          expect(data[:response][:aoa_consultant_ids]).to eq([])
          expect(data[:response][:request_uuid]).to eq(nil)
          expect(data[:response][:cohort]).to eq("control_group")
        end
      end
    end
  end
end
