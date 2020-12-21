# frozen_string_literal: true

require "rails_helper"
require "composites/home24/exporter/sftp/fake_client"

RSpec.describe Home24::Exporter::Sftp::FakeClient do
  subject { described_class.new }

  let(:file_path_tu_upload) { "test.zip" }
  let(:remote_file_path) { "test.zip" }

  describe "#upload" do
    it "returns true" do
      expect(subject.upload(file_path_tu_upload, remote_file_path)).to be_truthy
    end
  end
end
