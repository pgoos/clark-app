# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::AccountingReportsController, :integration, type: :controller do
  let(:role) { create(:role, permissions: Permission.where(controller: "admin/accounting_reports")) }
  let(:admin) { create(:admin, role: role) }

  before do
    allow(Features).to receive(:active?).with(Features::ACCOUNTING).and_return(true)
    sign_in(admin)
  end

  describe "#create" do
    let(:document) do
      Rack::Test::UploadedFile.new(Rails.root.join("spec", "support", "assets", "fonds_finanz_accounting_report.xls"))
    end

    let(:params) do
      {
        locale: I18n.locale,
        accounting_report: {
          excel_file: document,
          source: :fonds_finanz
        }
      }
    end

    it "uploads xls" do
      post :create, params: params

      expect(Document.last).not_to be_nil
      expect(Document.last.document_type).to eq DocumentType.fonds_finanz_accounting_report
      expect(subject).to redirect_to(new_admin_accounting_report_path)
    end
  end

  describe "#payment_gap_csv" do
    let(:params) do
      {
        locale: I18n.locale,
        accounting_report: {
          from: 1.year.ago,
          to: Time.zone.now
        }
      }
    end

    it "schedules report generation" do
      expect(Domain::Finance::PaymentGapReport::GenerateAndSendJob).to receive(:perform_later)
      post :payment_gap_csv, params: params
      expect(subject).to redirect_to(new_admin_accounting_report_path)
    end
  end
end
