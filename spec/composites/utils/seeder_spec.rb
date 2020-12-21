# frozen_string_literal: true

require "composites/utils/seeder"
require "composites/utils/seeder/prevent_production_usage"
require "composites/utils/exceptions"
require "rails_helper"

RSpec.describe Utils::Seeder do
  before do
    class DummySeedClass
      include Utils::Seeder
      include Utils::Seeder::PreventProductionUsage
    end
  end

  context "when faking production" do
    before do
      allow(Rails.env).to receive(:production?).and_return(true)
    end

    after do
      allow(Rails.env).to receive(:production?).and_call_original
    end

    it "raise NotAllowedRailsEnv if rails env was production" do
      expect { DummySeedClass.new }.to raise_error(Utils::Exceptions::NotAllowedRailsEnv)
    end
  end

  context "when not faking production" do
    it "won't raise any exception if rails env wasn't production" do
      expect { DummySeedClass.new }.not_to raise_exception
    end
  end
end
