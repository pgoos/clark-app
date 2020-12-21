# frozen_string_literal: true

require "rails_helper"

RSpec.describe ComfortableMexicanSofa::Content::Tag::FileLink do
  let(:page) { Comfy::Cms::Page.new }
  let(:blob) { ActiveStorage::Blob.new(key: "path/to/file", filename: "test.png", byte_size: 1987, checksum: "123") }
  let(:file) { double("file", blob: blob, label: "", attachment: blob) }

  before do
    allow(Settings).to receive(:cdn_host).and_return("test_dsf34r.cloudfront.net")
    allow(page).to receive_message_chain(:site, :files, :detect).and_return(file)
  end

  after { Settings.reload! }
  subject { described_class.new(context: page, params: ["some-id"]).content(file: file, as: as) }

  context "as: url" do
    let(:as) { "url" }

    it "returns valid tag" do
      expect(subject).to eq "https://test_dsf34r.cloudfront.net/#{blob.key}"
    end
  end

  context "as: link" do
    let(:as) { "link" }

    it "returns valid tag" do
      expect(subject).to eq("<a href='https://test_dsf34r.cloudfront.net/#{blob.key}' target='_blank'>test.png</a>")
    end
  end

  context "as: image" do
    let(:as) { "image" }

    it "returns valid tag" do
      expect(subject).to eq("<img src='https://test_dsf34r.cloudfront.net/#{blob.key}' alt='test.png'/>")
    end
  end
end
