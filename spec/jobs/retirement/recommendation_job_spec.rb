# frozen_string_literal: true

require "rails_helper"

RSpec.describe Retirement::RecommendationJob, type: :job do
  it { is_expected.to be_a(ClarkJob) }

  describe ".perform" do
    let(:mandate) { create(:mandate) }
    let(:builder) { instance_double(Domain::Retirement::Recommendation::Builder, call: nil) }

    before do
      allow(Domain::Retirement::Recommendation::Builder).to receive(:new) { builder }

      subject.perform(mandate.id)
    end

    it { expect(builder).to have_received(:call) }
  end
end
