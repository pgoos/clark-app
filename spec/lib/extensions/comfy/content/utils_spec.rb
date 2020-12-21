# frozen_string_literal: true

require "rails_helper"

RSpec.describe ComfortableMexicanSofa::Content::Tag::Utils do
  describe ".cnd_url" do
    before { allow(Settings).to receive(:cdn_host).and_return("test_dsf34r.cloudfront.net") }

    after { Settings.reload! }

    [
      {
        url:    "comfy/cms/files/files/000/000/035/original/en-magnify-documents.png",
        result: "https://test_dsf34r.cloudfront.net/comfy/cms/files/files/000/000/035/original/en-magnify-documents.png"
      },
      {
        url:    "comfy/cms/files/files/000/000/035/original/en-magnify-documents.png",
        result: "https://test_dsf34r.cloudfront.net/comfy/cms/files/files/000/000/035/original/en-magnify-documents.png"
      }
    ].each do |example|
      it "returns valid url for #{example[:url]}" do
        expect(
          described_class.cdn_url(example[:url])
        ).to eq example[:result]
      end
    end
  end
end
