# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Reports::Marketing::SalesforceMarketingExtension do
  translation_key = "admin.marketing.reports.salesforce_marketing_extension"
  csv_data_row = %w[mandate_id subscriber latest_demand_check_complete_at
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
                    count_valid_hm_products count_valid_mm_products count_valid_lm_products
                    first_device_os phone_verification_success_at voucher_value rev_share_partner
                  ]

  expected_csv = CSV.generate do |csv|
    csv << described_class.new.repository.class.fields_order.map { |n| I18n.t("#{translation_key}.#{n}") }
    csv << csv_data_row
    csv << csv_data_row
  end

  it_behaves_like "a csv report", translation_key, nil, expected_csv

  it "is aware of locale" do
    expect(described_class.new.filename).to start_with('de_salesforce_marketing_extension_')

    allow(Internationalization).to receive(:locale).and_return(:at)
    expect(described_class.new.filename).to start_with('at_salesforce_marketing_extension_')
  end
end
