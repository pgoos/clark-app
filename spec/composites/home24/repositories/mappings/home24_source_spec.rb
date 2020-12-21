# frozen_string_literal: true

require "rails_helper"
require "composites/home24/repositories/mappings/home24_source"

RSpec.describe Home24::Repositories::Mappings::Home24Source do
  describe ".entity_value" do
    context "when source is home24" do
      let(:user) { double(source_data: { "adjust" => { "network" => "home24" } }) }

      it "returns true" do
        expect(described_class.entity_value(user)).to be_truthy
      end
    end

    context "when source is not home24" do
      let(:user) { double(source_data: { "anonymous_lead" => true }) }

      it "returns false" do
        expect(described_class.entity_value(user)).to be_falsey
      end
    end
  end
end
