# frozen_string_literal: true

require "rails_helper"
require "composites/sales"

RSpec.describe Sales::Constituents::Opportunity::Interactors::BuildAoaData do
  let(:bu_category) { create :category, ident: "3d439696" }
  let(:bu_opportunity) { create :opportunity, category: bu_category }
  let(:non_bu_opportunity) { create :opportunity }
  let(:error_message) { "API AOA error!" }

  let!(:admin1) { create :admin, access_flags: ["sales_consultation"] }
  let!(:admin2) { create :admin }
  let!(:admin3) { create :admin }
  let!(:admin4) { create :admin }

  let(:all_active_admin_ids) { Admin.active.map(&:id) }

  let(:aoa_suggested_consultant_ids) { [admin1.id, admin2.id, admin3.id] }

  let(:request_uuid) { Faker::String.random }

  let(:aoa_data_response) do
    OpenStruct.new(
      errors: [],
      request_uuid: request_uuid,
      aoa_ranks: Admin.active.where(id: aoa_suggested_consultant_ids).map(&:id)
    )
  end

  let(:aoa_data_response_with_error) do
    OpenStruct.new(
      errors: [error_message],
      request_uuid: request_uuid,
      aoa_ranks: []
    )
  end

  context "aoa test group" do
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
          data = subject.call(bu_opportunity).data_for_ui

          expect(data[:admins_for_select].map(&:id)).to match_array(all_active_admin_ids)
          expect(data[:response][:aoa_errors]).to eq([])
          expect(data[:response][:request_uuid]).to eq(nil)
          expect(data[:response][:aoa_consultant_ids]).to eq([])
        end
      end

      context "with not assigned consultant" do
        before do
          bu_opportunity.update!(admin_id: nil)
        end

        context "aoa response without errors" do
          before do
            allow_any_instance_of(described_class)
              .to receive(:aoa_response)
              .and_return(aoa_data_response)
          end

          it "returns valid data" do
            data = subject.call(bu_opportunity).data_for_ui

            expect(data[:admins_for_select].map(&:id)).to match_array(aoa_suggested_consultant_ids)
            expect(data[:response][:aoa_errors]).to eq([])
            expect(data[:response][:aoa_consultant_ids]).to match_array(aoa_suggested_consultant_ids)
            expect(data[:response][:cohort]).to eq("aoa_group")
            expect(data[:response][:request_uuid]).to eq(request_uuid)
          end
        end

        context "opportunity is not belongs to 'BU' category" do
          before do
            allow_any_instance_of(described_class)
              .to receive(:aoa_response)
              .and_return(aoa_data_response)
          end

          it "returns valid data" do
            data = subject.call(non_bu_opportunity).data_for_ui

            expect(data[:admins_for_select].map(&:id)).to match_array(all_active_admin_ids)
            expect(data[:response][:aoa_errors]).to eq([])
            expect(data[:response][:aoa_consultant_ids]).to match_array([])
            expect(data[:response][:cohort]).to eq("control_group")
            expect(data[:response][:request_uuid]).to eq(nil)
          end
        end

        context "anyone from consultants has not 'sales_consultation' grants" do
          before do
            allow_any_instance_of(described_class)
              .to receive(:aoa_response)
              .and_return(aoa_data_response)

            admin1.update!(access_flags: [])
          end

          it "returns valid data" do
            data = subject.call(bu_opportunity).data_for_ui

            expect(data[:admins_for_select].map(&:id)).to match_array(all_active_admin_ids)
            expect(data[:response][:aoa_errors]).to eq([])
            expect(data[:response][:aoa_consultant_ids]).to match_array([])
            expect(data[:response][:cohort]).to eq("control_group")
            expect(data[:response][:request_uuid]).to eq(nil)
          end
        end

        context "aoa response with errors" do
          before do
            allow_any_instance_of(described_class)
              .to receive(:aoa_response)
              .and_return(aoa_data_response_with_error)
          end

          it "returns valid data" do
            data = subject.call(bu_opportunity).data_for_ui

            expect(data[:admins_for_select].map(&:id)).to match_array(all_active_admin_ids)
            expect(data[:response][:aoa_errors]).to eq([error_message])
            expect(data[:response][:aoa_consultant_ids]).to eq([])
            expect(data[:response][:cohort]).to eq("control_group")
            expect(data[:response][:request_uuid]).to eq(request_uuid)
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
          data = subject.call(bu_opportunity).data_for_ui

          expect(data[:admins_for_select].map(&:id)).to match_array(all_active_admin_ids)
          expect(data[:response][:aoa_errors]).to eq([])
          expect(data[:response][:aoa_consultant_ids]).to eq([])
          expect(data[:response][:cohort]).to eq("control_group")
          expect(data[:response][:request_uuid]).to eq(nil)
        end
      end

      context "with not assigned consultant" do
        before do
          bu_opportunity.update!(admin_id: nil)
        end

        it "returns valid data" do
          data = subject.call(bu_opportunity).data_for_ui

          expect(data[:admins_for_select].map(&:id)).to match_array(all_active_admin_ids)
          expect(data[:response][:aoa_errors]).to eq([])
          expect(data[:response][:aoa_consultant_ids]).to eq([])
          expect(data[:response][:cohort]).to eq("control_group")
          expect(data[:response][:request_uuid]).to eq(nil)
        end
      end
    end
  end

  context "control group" do
    before do
      allow_any_instance_of(described_class)
        .to receive(:test_percentage_value)
        .and_return("0")

      allow(Features)
        .to receive(:active?)
        .with(Features::API_NOTIFY_PARTNERS)
        .and_return(false)

      allow(Features)
        .to receive(:active?)
        .with(Features::AOA_BASED_CONSULTANT_ASSIGNMENT)
        .and_return(true)

      bu_opportunity.update!(admin_id: nil)
    end

    it "returns valid data" do
      data = subject.call(bu_opportunity).data_for_ui

      expect(data[:admins_for_select].map(&:id)).to match_array(all_active_admin_ids)
      expect(data[:response][:aoa_errors]).to eq([])
      expect(data[:response][:aoa_consultant_ids]).to eq([])
      expect(data[:response][:cohort]).to eq("control_group")
      expect(data[:response][:request_uuid]).to eq(nil)
    end
  end
end
