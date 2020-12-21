# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::TvSpotsController, :integration, type: :controller do
  let(:role)  { create(:role, permissions: Permission.where(controller: "admin/tv_spots")) }
  let(:admin) { create(:admin, role: role) }

  before { login_admin(admin) }

  describe "GET /new_csv_upload" do
    it { expect(response).to be_ok }
  end

  describe "POST /csv_upload" do
    let(:staring_at) { "2016-05-01" }
    let(:ending_at) { "2016-05-02" }
    let(:csv_file) {
      fixture_file_upload(Rails.root.join("spec/fixtures/files/tv_spots/sample_tv_spots.csv"), "text/csv")
    }

    before do
      allow(Platform::FileUpload).to receive(:persist_file).and_return(double(Document, id: 1))
      allow(TvCostUploadJob).to receive(:perform_later)
    end

    context "with valid params" do
      it "will not start parsing the file if no starting date is provided" do
        expect(Platform::FileUpload).not_to receive(:persist_file)
        post :csv_upload, params: {ending_at: ending_at, csv_file: csv_file, locale: :de}
      end

      it "will not start parsing the file if no ending date is provided" do
        expect(Platform::FileUpload).not_to receive(:persist_file)
        post :csv_upload, params: {starting_from: staring_at, csv_file: csv_file, locale: :de}
      end

      it "will not start parsing the file if no csv file is provided" do
        expect(Platform::FileUpload).not_to receive(:persist_file)
        post :csv_upload, params: {starting_from: staring_at, ending_at: ending_at, locale: :de}
      end

      it "will not start parsing if start date is greater than end date" do
        expect(Platform::FileUpload).not_to receive(:persist_file)
        post :csv_upload, params: {starting_from: ending_at, ending_at: staring_at, csv_file: csv_file, locale: :de}
      end
    end

    context "with valid params" do
      it "creates a job, to run later if all valid params are present" do
        expect(Platform::FileUpload).to receive(:persist_file)
        post :csv_upload, params: {starting_from: staring_at, ending_at: ending_at, csv_file: csv_file, locale: :de}
      end
    end
  end
end
