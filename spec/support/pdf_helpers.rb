# frozen_string_literal: true

RSpec.configure do |config|
  config.before do
    allow_any_instance_of(PDFKit).to receive(:to_pdf).and_return("Dummy PDF")
  end
end
