# frozen_string_literal: true

RSpec.shared_examples "a ocr data uploader" do
  before do
    task.reenable

    allow(::OCR::Service).to receive(:new).and_return ocr_service_double
    allow(ocr_service_double).to receive(:write_master_data)
  end

  context "with feature switch on" do
    before { allow(Features).to receive(:active?).with(Features::OCR_MASTER_DATA_UPLOAD).and_return(true) }

    it "sends the correct data to OCR::Service" do
      task.invoke
      expect(ocr_service_double).to \
        have_received(:write_master_data)
        .with(
          table,
          columns,
          match_array(data),
          true
        )
    end
  end

  context "with feature switch off" do
    it "does not synchronize data" do
      expect(ocr_service_double).not_to have_received(:write_master_data)
    end
  end
end
