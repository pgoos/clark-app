# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::AdvertisementPerformanceLogsController, :integration, type: :controller do
  let(:role)  { create(:role, permissions: Permission.where(controller: "admin/advertisement_performance_logs")) }
  let(:admin) { create(:admin, role: role) }

  before { login_admin(admin) }

  describe "GET /batch_import" do
    it { expect(response).to be_ok }
  end

  describe "POST /upload" do
    let(:starting_from) { "2020-03-01" }
    let(:ending_at) { "2020-03-30" }
    let(:ad_provider) { "Facebook" }
    let(:brand) { "true" }
    let(:csv_file) {
      fixture_file_upload(Rails.root.join("spec/fixtures/files/advertisement_performance_logs/cost_sample.csv"),
                          "text/csv")
    }
    let(:document_id) { 1 }

    before do
      allow(Platform::FileUpload).to receive(:persist_file).and_return(double(Document, id: document_id))
      allow(AdvertisementPerformanceLogImportJob).to receive(:perform_later).and_return(true)
    end

    context "when one of required params is missing" do
      it "will not start uploading the file if no starting date is provided" do
        expect(Platform::FileUpload).not_to receive(:persist_file)

        post :upload, params: {
          ending_at: ending_at,
          ad_provider: ad_provider,
          brand: brand,
          csv_file: csv_file,
          locale: :de
        }
      end

      it "will not start uploading the file if no ending_at date is provided" do
        expect(Platform::FileUpload).not_to receive(:persist_file)

        post :upload, params: {
          starting_from: starting_from,
          ad_provider: ad_provider,
          brand: brand,
          csv_file: csv_file,
          locale: :de
        }
      end

      it "will not start uploading the file if no ad provider is provided" do
        expect(Platform::FileUpload).not_to receive(:persist_file)

        post :upload, params: {
          starting_from: starting_from,
          ending_at: ending_at,
          brand: brand,
          csv_file: csv_file,
          locale: :de
        }
      end

      it "will not start uploading the file if file is provided" do
        expect(Platform::FileUpload).not_to receive(:persist_file)

        post :upload, params: {
          starting_from: starting_from,
          ending_at: ending_at,
          ad_provider: ad_provider,
          brand: brand,
          locale: :de
        }
      end
    end

    context "when the range of the dates is not correct" do
      let(:starting_from) { "2020-03-15" }
      let(:ending_at) { "2020-03-02" }

      it "will not uploading parsing the file " do
        expect(Platform::FileUpload).not_to receive(:persist_file)

        post :upload, params: {
          starting_from: starting_from,
          ending_at: ending_at,
          ad_provider: ad_provider,
          brand: brand,
          csv_file: csv_file,
          locale: :de
        }

        expect(@controller.instance_variable_get(:@errors))
          .to eq([I18n.t("admin.advertisement_performance_log.errors.date_range")])
      end
    end

    context "all the params are valid" do
      it "will start uploading the file " do
        expect(Platform::FileUpload).to receive(:persist_file)

        post :upload, params: {
          starting_from: starting_from,
          ending_at: ending_at,
          ad_provider: ad_provider,
          brand: brand,
          csv_file: csv_file,
          locale: :de
        }
      end

      it "will schedule the job for the importer" do
        expect(AdvertisementPerformanceLogImportJob)
          .to receive(:perform_later).with(document_id: document_id,
                                           starting_from: starting_from,
                                           ending_at: ending_at,
                                           ad_provider: ad_provider,
                                           brand: brand,
                                           admin_email: admin.email)

        post :upload, params: {
          starting_from: starting_from,
          ending_at: ending_at,
          ad_provider: ad_provider,
          brand: brand,
          csv_file: csv_file,
          locale: :de
        }
      end
    end
  end
end
