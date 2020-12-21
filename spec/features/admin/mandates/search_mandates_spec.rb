# frozen_string_literal: true

require "rails_helper"

RSpec.describe "searching customers / mandates", :slow, :browser, :js, type: :feature do
  before do
    login_super_admin
  end

  context ":locale/admin/mandates" do
    let(:mandates_index_page) { MandatesIndexPage.new }

    before do
      mandates_index_page.go
    end

    context "with product number search" do
      let(:mandates_search_right) { MandateSearchRight.new }
      let(:mandate) { create(:mandate, :accepted, user: create(:user)) }
      let(:product_no) { "some_number_#{rand(100)}" }

      before do
        create(:product, number: product_no, mandate: mandate)
        mandates_search_right.assert_visible
      end

      it "should find the customer" do
        mandates_search_right.search_by_insurance_product_number(product_no)
      end
    end
  end
end
