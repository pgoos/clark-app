# frozen_string_literal: true

require "rails_helper"
require "./spec/support/features/page_objects/ember/mandate-funnel/cockpit_preview_page"

RSpec.describe "Primoco Bank Mandate funnel process",
               :browser, type: :feature, js: true,
                         skip: "@Steffen skipping this due to problems with selenium" do

  let!(:flow_funnel_flow_page) { PrimocoFunnelFlowPage.new }
  let!(:company_one) { create(:company, name: 'Jelly Fish') }
  let!(:company_two) { create(:company, name: 'Rojer rabbit') }

  let!(:category_one) { create(:category, name: 'Silly things') }
  let!(:category_two) { create(:category, name: 'Are expected') }

  let!(:admin) { create(:admin) }
  let!(:phone_reg_page) { PhoneRegistrationPage.new }

  let!(:lead) { create(:lead, email: "peter.prospect@test.clark.de", source_data: {"adjust": {"network": "primoco"}}) }

  context "Primoco network starts the mandate funnel" do
    before do
      login_as(lead, scope: :lead)
      flow_funnel_flow_page.visit_status
    end

    it "green path" do
      flow_funnel_flow_page.navigate_click(".btn-primary", "/#{locale}/app/mandate/phone-verification")
      phone_reg_page.does_phone_registration
      flow_funnel_flow_page.expect_cockpit_preview
      flow_funnel_flow_page.navigate_click(".btn-primary", "/#{locale}/app/mandate/targeting")
      flow_funnel_flow_page.visit_cockpit_targeting
      flow_funnel_flow_page.expect_cockpit_targeting
      flow_funnel_flow_page.click_category(category_one.id)
      flow_funnel_flow_page.expect_company_selection_page
      flow_funnel_flow_page.click_company(company_one.id)
      flow_funnel_flow_page.expect_cockpit_targeting
      flow_funnel_flow_page.click_cta
      flow_funnel_flow_page.expect_profiling
      flow_funnel_flow_page.fill_in_profiling
    end
  end
end
