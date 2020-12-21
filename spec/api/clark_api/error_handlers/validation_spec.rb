# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::ErrorHandlers::Validation do
  subject { described_class.new(rails_env) }

  let(:rails_env) { double(:rails_env) }
  let(:request_env) { double(:request_env) }

  let(:v1) { "simple" }
  let(:v2) { "composite" }
  let(:v3) { "composite" }
  let(:v4) { "composite[value]" }
  let(:a1) { double(:attr1, first: v1) }
  let(:a2) { double(:attr2, first: v2) }
  let(:a3) { double(:attr3, first: v3) }
  let(:a4) { double(:attr4, first: v4) }
  let(:m1) { "Message 1" }
  let(:m2) { "Message 2" }
  let(:m3) { "Message 3" }
  let(:m4) { "Message 4" }

  let(:exception) do
    {
      a1 => m1,
      a2 => m2,
      a3 => m3,
      a4 => m4
    }
  end

  describe "#error_content" do
    let(:error_content) { subject.error_content(exception) }

    it { expect(error_content[:api][v1]).to include(m1) }
    it { expect(error_content[:api][v2]).to include(m2) }
    it { expect(error_content[:api][v2]).to include(m3) }
    it { expect(error_content[v3]["value"]).to include(m4) }
  end
end
