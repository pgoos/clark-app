# frozen_string_literal: true

RSpec.shared_examples "a csv report" do |translation_key, default_encoding, default_expected_csv|
  def report_permissions(enabled:, allowed_admins: [])
    allow(Settings).to(
      receive_message_chain("reporting", "permissions", :[]).and_return(
        enabled: enabled,
        allowed_admins: allowed_admins
      )
    )
  end

  let(:repository_class) { subject.repository.class }

  let(:report_data) do
    [report_record, report_record]
  end

  let(:report_record) do
    Hash[repository_class.fields_order.map { |field| [field, field] }]
  end

  before do
    allow_any_instance_of(repository_class).to receive(:all).and_return(report_data)
  end

  describe "#generate_csv" do
    let(:expected_csv) do
      return default_expected_csv if default_expected_csv

      text = CSV.generate do |csv|
        csv << repository_class.fields_order.map { |n| I18n.t("#{translation_key}.#{n}") }
        csv << repository_class.fields_order
        csv << repository_class.fields_order
      end

      return text unless default_encoding

      text.encode(default_encoding)
    end

    it "generates CSV report" do
      expect(subject.generate_csv).to eq(expected_csv)
    end

    it "has all the necessary translation keys" do
      expect(I18n.t(translation_key).keys.map(&:to_s)).to include(*repository_class.fields_order)
    end
  end

  describe "#enabled" do
    context "when report is enabled" do
      before { report_permissions(enabled: true) }

      it "returns true" do
        expect(described_class).to be_enabled
      end
    end

    context "when report is disabled" do
      before { report_permissions(enabled: false) }

      it "returns false" do
        expect(described_class).not_to be_enabled
      end
    end
  end

  describe "#permitted_for" do
    let(:admin_email) { "admin@test.com" }
    let!(:admin) { build(:admin, email: admin_email) }

    before do
      report_permissions(enabled: report_enabled, allowed_admins: allowed_admins)
    end

    context "when report is enabled" do
      let(:report_enabled) { true }

      context "when any admin allowed" do
        let(:allowed_admins) { [] }

        it "returns true" do
          expect(described_class).to be_permitted_for(admin)
        end
      end

      context "when admin is allowed" do
        let(:allowed_admins) { [admin_email] }

        it "returns true" do
          expect(described_class).to be_permitted_for(admin)
        end
      end

      context "when admin admin isn't allowed" do
        let(:allowed_admins) { %w[some_another_admin@test.com] }

        it "returns false" do
          expect(described_class).not_to be_permitted_for(admin)
        end
      end
    end

    context "when report is disabled" do
      let(:report_enabled) { false }

      context "when any admin allowed" do
        let(:allowed_admins) { [] }

        it "returns false" do
          expect(described_class).not_to be_permitted_for(admin)
        end
      end
    end
  end
end
