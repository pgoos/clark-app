# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::BusinessEventsHelper do
  describe "#back_button_link" do
    before do
      allow(helper).to receive(:current_namespace).and_return("admin")
      allow(helper).to receive(:current_parent).and_return(parent_resource)
    end

    context "parent resource is offer" do
      let(:parent_resource) { build_stubbed(:offer) }

      it "returns link" do
        expect(helper).to receive(:link_to).with(["admin", parent_resource.opportunity, :offer], nil, nil)
        helper.back_button_link { "test" }
      end
    end

    context "parent resource is mandate" do
      let(:parent_resource) { build_stubbed(:mandate) }

      before do
        allow(helper).to receive(:current_namespace).and_return("admin")
        allow(helper).to receive(:current_parent).and_return(parent_resource)
      end

      it "returns link" do
        expect(helper).to receive(:link_to).with(["admin", parent_resource], nil, nil)
        helper.back_button_link { "test" }
      end
    end
  end
end
