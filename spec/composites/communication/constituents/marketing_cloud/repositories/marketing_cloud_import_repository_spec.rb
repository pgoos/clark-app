# frozen_string_literal: true

require "rails_helper"

RSpec.describe Communication::Constituents::MarketingCloud::Repositories::MarketingCloudImportRepository, :integration do
  describe "#pending_marketing_cloud_imports" do
    context "when multiple marketing cloud imports exists" do
      let!(:unprocessed_marketing_cloud_import) { create(:marketing_cloud_import) }
      let!(:processed_marketing_cloud_import) { create(:marketing_cloud_import, :processed) }

      it "return only pending marketing cloud imports" do
        result = subject.pending_marketing_cloud_imports

        expect(result.count).to eq(1)
        expect(result[0]).to be_a(
          Communication::Constituents::MarketingCloud::Entities::MarketingCloudImport
        )
        expect(result[0].id).to eq(unprocessed_marketing_cloud_import.id)
      end
    end
  end

  describe "#read_marketing_cloud_import_file" do
    let(:marketing_cloud_import) { create(:marketing_cloud_import) }

    context "when marketing_cloud_import has csv file" do
      it "returns csv parsed" do
        UTF_16_BOM = 65279
        expected_parsed_data = [
          "#{UTF_16_BOM.chr(Encoding::UTF_8)}mandate_id",
          "subscriber_id",
          "subscriber_key",
          "primary_key",
          "direction",
          "sent_at",
          "open_at",
          "click_at",
          "email_name",
          "job_id",
          "bounced_at",
          "bounce_type",
          "unsubscribed_at",
          "complained_at",
          "account_id",
          "campaign_name",
          "channel",
          "bounce_reason",
          "delivered_at"
        ]
        result = subject.read_marketing_cloud_import_file(marketing_cloud_import.id)

        expect(result).to be_an(Array)
        expect(result[0]).to match(expected_parsed_data)
      end
    end
  end

  describe "#bulk_insert_interactions!" do
    context "when interaction params are passed" do
      it "calls ActiveRecord create! method" do
        expect(::Interaction).to receive(:create!).with([])

        subject.bulk_insert_interactions!([])
      end
    end
  end

  describe "#mark_import_as_completed" do
    context "when called with valid import_id" do
      it "update marketing_cloud_import as processed" do
        Timecop.freeze(Time.current) do
          marketing_cloud_import = create(:marketing_cloud_import)

          expect {
            subject.mark_import_as_completed(marketing_cloud_import.id)
          }.to change { marketing_cloud_import.reload.processed_at }
        end
      end
    end
  end

  describe "#bot_admin_id" do
    let!(:bot) { create(:admin) }

    context "when SF MC Campaign Bot exists" do
      let!(:sf_mc_bot) { create(:admin, first_name: "SF MC Campaign Bot") }

      it "return admin id of SF MC Campaign Bot" do
        expect(subject.bot_admin_id).to eq(sf_mc_bot.id)
      end
    end

    context "when SF MC Campaign Bot does not exists" do
      it "return admin id of first admin" do
        expect(subject.bot_admin_id).to eq(bot.id)
      end
    end
  end
end
