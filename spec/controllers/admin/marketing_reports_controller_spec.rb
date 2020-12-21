# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::MarketingReportsController, :integration, type: :controller do
  let(:role) { create(:role, permissions: Permission.where(controller: "admin/marketing_reports")) }
  let(:admin) { create(:admin, role: role) }

  before { sign_in(admin) }

  describe "#insurance_incentive" do
    it "should schedule InsuranceIncentiveReportJob job" do
      expect(MarketingReportJob)
        .to receive(:perform_later)
        .with("InsuranceIncentive", admin.email)
        .and_return(MarketingReportJob)

      get :insurance_incentive, params: {locale: :de}, format: :csv
    end

    it "should redirect to marketing overview page" do
      get :insurance_incentive, params: {locale: :de}, format: :csv
      expect(response).to redirect_to(admin_marketing_overview_path)
    end
  end

  describe "#incentive_payout" do
    it "should not schedule IncentivePayoutReportJob job" do
      expect(MarketingReportJob).not_to receive(:perform_later)

      get :incentive_payout, params: { locale: :de }, format: :csv
    end

    it "should schedule IncentivePayoutReportJob job", skip: true do
      expect(MarketingReportJob)
        .to receive(:perform_later)
        .with("IncentivePayout", admin.email)
        .and_return(MarketingReportJob)

      get :incentive_payout, params: {locale: :de}, format: :csv
    end

    it "should redirect to marketing overview page" do
      get :incentive_payout, params: {locale: :de}, format: :csv
      expect(response).to redirect_to(admin_marketing_overview_path)
    end
  end
end
