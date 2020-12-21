# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::MasterData::Utils::Memoizable do
  subject { Class.new { extend Domain::MasterData::Utils::Memoizable } }

  describe ".memoize" do
    let(:variable_name) { "test" }
    let(:retention_time) { 30.minutes }
    let(:result) { "result" }

    before do
      allow(subject).to receive(:retention_time).and_return(retention_time)
      subject.memoize(variable_name) { result }
    end

    it "initializes and register the instance variable according to the argument" do
      expect(subject.instance_variable_get("@#{variable_name}")).to eq(result)
      expect(subject.instance_variable_get("@memoized_variables")).to include("@#{variable_name}")
    end

    it "initializes @expiry_time variable" do
      expect(subject.instance_variables).to include(:@expiry_time)
    end

    context "when cache is expired" do
      let(:post_retention_time) { 2.minutes.from_now + retention_time }
      let(:new_result) { "new result" }

      before { Timecop.freeze(post_retention_time) }

      after { Timecop.return }

      it "invalidates old cache and set new expiry_time" do
        subject.memoize(variable_name) { new_result }

        expect(subject.instance_variable_get(:@expiry_time)).to eq(post_retention_time + retention_time)
        expect(subject.instance_variable_get("@#{variable_name}")).to eq(new_result)
      end
    end

    context "when cache is not expired" do
      let(:pre_retention_time) { retention_time.from_now - 2.minutes }

      before { Timecop.freeze(pre_retention_time) }

      after { Timecop.return }

      it "returns cached data" do
        prev_expiry_time = subject.instance_variable_get(:@expiry_time)
        subject.memoize(variable_name) { [] }

        expect(subject.instance_variable_get(:@expiry_time)).to eq(prev_expiry_time)
        expect(subject.instance_variable_get("@#{variable_name}")).to eq(result)
      end
    end
  end
end
