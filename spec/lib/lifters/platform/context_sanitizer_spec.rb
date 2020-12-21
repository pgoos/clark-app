# frozen_string_literal: true

require "spec_helper"

require "lifters/platform/context_sanitizer"

RSpec.describe ContextSanitizer do
  context "sanitize ActiveJob keys from context" do
    let(:expected_context) { {key: "value"} }
    let(:context) { {_aj_globalid: "gid://app/model/id", key: "value"} }

    it "removes reserved keys" do
      new_context = described_class.sanitize(context)

      expect(new_context).to eq(expected_context)
    end
  end

  context "sanitize ActiveJob keys from nested context" do
    let(:expected_context) { {arguments: {"key" => "value"}} }
    let(:context) do
      {
        _aj_globalid: "gid://app/model/id",
        arguments: {"key" => "value", "_aj_symbol_keys" => ["key"]}
      }
    end

    it "removes reserved keys" do
      new_context = described_class.sanitize(context)

      expect(new_context).to eq(expected_context)
    end
  end
end
