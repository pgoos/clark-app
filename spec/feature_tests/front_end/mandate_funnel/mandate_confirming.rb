# frozen_string_literal: true

require "rails_helper"
require "./spec/support/features/page_objects/ember/mandate-funnel/mandate_confirming_page"



RSpec.describe "Ember Mandate Confirming", :browser, type: :feature, js: true do
  let(:locale) { I18n.locale }
  let!(:confirming_po) { MandateConfirmingPage.new }

  let!(:user) do
    user = create(:user)
    user.update_attributes(mandate: create(:mandate))
    user.mandate.signature = create(:signature)
    user.mandate.confirmed_at = DateTime.current
    user.mandate.tos_accepted_at = DateTime.current
    user.mandate.info['wizard_steps'] = %w[profiling targeting]
    user.mandate.save!
    user
  end

  context "TOS modal" do
    before do
      login_as(user, scope: :user)
      confirming_po.visit_confirming
    end

    it "should show the correct information and sections" do
      confirming_po.open_tos_modal
      confirming_po.expect_point_of_contact("Marco")
      confirming_po.expect_sigature_in_tos_modal
      confirming_po.expect_tos_modal_contains("Clark")
    end
  end

  context "Consent modal" do
    before do
      login_as(user, scope: :user)
      confirming_po.visit_confirming
    end

    it "should show and work correctly" do
      confirming_po.scroll_down
      confirming_po.expect_consent_section
      confirming_po.open_consent_modal
    end
  end
end
