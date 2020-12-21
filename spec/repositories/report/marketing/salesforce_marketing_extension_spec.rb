# frozen_string_literal: true

require "rails_helper"

RSpec.describe Report::Marketing::SalesforceMarketingExtension, :integration do
  describe ".fields_order" do
    it "returns fields_order" do
      expect(described_class.fields_order).to eq(
        %w[mandate_id subscriber latest_demand_check_complete_at
           first_demand_check_complete_at latest_demand_check_started_at
           hm_sales_in_progress sales_in_progress count_products_under_management
           insurance_purchase_count last_sign_in_at customer_state
           last_hm_complete_at last_mm_complete_at last_lm_complete_at
           sign_in_count mkt_channel network campaign nps_score nps_answered_at
           first_app_install_date app_install push_enabled revenue_generating
           product_portfolio has_valid_bu_product grossincome clark_version
           last_insurance_purchased_name last_insurance_purchased_date age
           user_is_referee count_invites last_referral_date count_completed_demand_checks
           plans_finance_property pets is_traveller family_time has_vehicle has_auto
           last_abandoned_questionnaire_date last_abandoned_questionnaire_identifier
           count_valid_hm_products count_valid_mm_products count_valid_lm_products first_device_os
           phone_verification_success_at voucher_value rev_share_partner]
      )
    end
  end

  describe "#all" do
    it "runs query" do
      create(:mandate)
      service = described_class.new
      allow(service).to receive(:query).and_return("select * from mandates")
      expect(service.all.size).to eq 1
    end
  end
end
