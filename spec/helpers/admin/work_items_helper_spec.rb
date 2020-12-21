# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::WorkItemsHelper do
  describe "#link_to_paginated_work_items_view?" do
    before do
      allow(helper).to receive(:current_locale).and_return(:de)
      allow(helper).to receive_message_chain(:params, :[]).and_return(nil)
    end

    it "returns link" do
      expect(helper.link_to_paginated_work_items_view("title", 1, "item", nil)).to eq(
        "<a class=\"page-link\" href=\"/de/admin/work_items?page=1#item\">title</a>"
      )
    end

    context "margin_level in params defined" do
      before { allow(helper).to receive_message_chain(:params, :[]).with(:margin_level).and_return("low") }

      it "returns link with margin_level" do
        expect(helper.link_to_paginated_work_items_view("title", 2, "item", nil)).to eq(
          "<a class=\"page-link\" href=\"/de/admin/work_items?margin_level=low&amp;page=2#item\">title</a>"
        )
      end
    end

    context "appointment_scheduled in params defined" do
      before { allow(helper).to receive_message_chain(:params, :[]).with(:appointment_scheduled).and_return("yes") }

      it "returns link with appointment_scheduled" do
        expect(helper.link_to_paginated_work_items_view("title", 3, "item", nil)).to eq(
          "<a class=\"page-link\" href=\"/de/admin/work_items?appointment_scheduled=yes&amp;page=3#item\">title</a>"
        )
      end
    end

    context "category_idents in params defined" do
      before { allow(helper).to receive_message_chain(:params, :[]).with(:category_idents).and_return(["21r2y1"]) }

      it "returns link with category_idents" do
        expect(helper.link_to_paginated_work_items_view("title", 1, "item", nil)).to eq(
          "<a class=\"page-link\" href=\"/de/admin/work_items?category_idents%5B%5D=21r2y1&amp;page=1#item\">title</a>"
        )
      end
    end
  end
end
