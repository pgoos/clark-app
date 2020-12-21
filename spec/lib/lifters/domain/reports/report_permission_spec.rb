# frozen_string_literal: true

require "spec_helper"
require "dry-struct"
require_relative "../../../../../config/initializers/dry_types"
require_relative "../../../../../lib/lifters/domain/reports/report_permission"

RSpec.describe Domain::Reports::ReportPermission do
  describe ".new" do
    let(:enabled) { true }
    let(:allowed_admins) { %w[admin@example.com] }

    let(:attributes) do
      {
        enabled: enabled,
        allowed_admins: allowed_admins
      }
    end

    it "maps the correct attributes" do
      report_permission = described_class.new(attributes)

      expect(report_permission.enabled).to eq(enabled)
      expect(report_permission.allowed_admins).to eq(allowed_admins)
    end

    it "ensure attribute types" do
      report_permission = described_class.new(attributes)

      expect(report_permission.enabled).to be_a(TrueClass)
      expect(report_permission.allowed_admins).to be_an(Array)
    end

    it "maps default attributes when nil is provided" do
      report_permission = described_class.new(nil)

      expect(report_permission.enabled).to eq(false)
      expect(report_permission.allowed_admins).to eq([])
    end
  end

  describe "#permitted_for?" do
    let(:admin) do
      double(:admin, email: "admin@example.com")
    end

    let(:attributes) do
      {
        enabled: true,
        allowed_admins: allowed_admins
      }
    end

    let!(:call) { described_class.new(attributes).permitted_for?(admin) }

    context "when admin is allowed" do
      let(:allowed_admins) { %w[admin@example.com] }

      it "returns true" do
        expect(call).to eq(true)
      end
    end

    context "when admin isn't allowed" do
      let(:allowed_admins) { %w[another_admin@example.com] }

      it "returns false" do
        expect(call).to eq(false)
      end
    end

    context "when any admin is allowed" do
      let(:allowed_admins) { [] }

      it "returns true" do
        expect(call).to eq(true)
      end
    end
  end
end
