# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Product management", :slow, :browser, type: :feature do
  let(:resource) { create(:product) }
  let(:fill_ins) do
    {
      product_notes:                                "Fake notes",
      product_premium_price:                        139,
      product_acquisition_commission_payouts_count: 5
    }
  end

  before do
    login_super_admin
  end

  describe "edit" do
    it "should be able to edit a product" do
      visit edit_admin_product_path(resource.id, locale: locale)
      i_fill_in_text_fields(fill_ins)
      a_resource_is_updated(Product)
      i_see_text_fields(fill_ins.values)
    end
  end

  describe "show" do
    context "interaction tabs" do
      let(:advice_tab) { CreateAdviceTab.new }
      let(:advice_reply_tab) { CreateAdviceReplyTab.new }

      it "interaction tabs should exist" do
        visit admin_product_path(resource.id, locale: locale)

        advice_tab.activate_tab
        advice_tab.assert_visible?

        advice_reply_tab.activate_tab
        advice_reply_tab.assert_visible?

        # TODO: add checks for other interaction types https://clarkteam.atlassian.net/browse/JCLARK-27577
      end
    end
  end
end
