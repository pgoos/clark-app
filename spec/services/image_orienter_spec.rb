# frozen_string_literal: true

require "rails_helper"

RSpec.describe ImageOrienter do
  describe ".call" do
    let(:file) { Tempfile.new }
    let(:image) { double(:image) }

    it "auto orients image" do
      allow(MiniMagick::Image).to receive(:open).with(file.path).and_return(image)
      allow(image).to receive(:write)

      expect(image).to receive(:auto_orient)
      described_class.call(file)
    end
  end
end
