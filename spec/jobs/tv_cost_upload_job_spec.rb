# frozen_string_literal: true

require "rails_helper"

RSpec.describe TvCostUploadJob, type: :job do
  let(:admin) { create(:admin) }
  let(:csv_file) {
    Rack::Test::UploadedFile.new Rails.root.join("spec/fixtures/files/tv_spots/sample_tv_spots.csv"), "text/csv"
  }
  let(:staring_at) { "2016-05-01" }
  let(:ending_at) { "2016-05-02" }
  let(:brand) { true }

  before do
    Platform::FileUpload.persist_file(csv_file, admin, DocumentType.csv)
  end

  context "TVCostUpload job is executed" do
    it { is_expected.to be_a(ClarkJob) }

    it "destroys the old entries between the start date and end date before creating new ones" do
      in_range_tv_spot = create(:tv_spot, air_time: Time.new(2016, 5, 1).in_time_zone, brand: brand)
      out_range_tv_spot = create(:tv_spot, air_time: Time.new(2016, 5, 3).in_time_zone, brand: brand)
      subject.perform(starting_at: staring_at,
                      ending_at: ending_at,
                      csv_id: Document.last.id,
                      email: "abujahal@mecca.sa",
                      brand: brand)
      expect { in_range_tv_spot.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { out_range_tv_spot.reload }.not_to raise_error
    end

    it "creates tv spots entries that fall in the range between start and end date" do
      subject.perform(starting_at: staring_at,
                      ending_at: ending_at,
                      csv_id: Document.last.id,
                      email: admin.email,
                      brand: brand)
      expect(TvSpot.count).to eq(2)
    end

    it "deletes the document local copy and the database entry" do
      expect {
        subject.perform(starting_at: staring_at, ending_at: ending_at, csv_id: Document.last.id, email: admin.email)
      }.to change(Document, :count).by(-1)
    end

    it "marks entries with brand attribute" do
      subject.perform(starting_at: staring_at,
                      ending_at: ending_at,
                      csv_id: Document.last.id,
                      email: admin.email,
                      brand: brand)
      expect(TvSpot.last.brand).to be_truthy
    end
  end
end
