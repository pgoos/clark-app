# frozen_string_literal: true

require "rails_helper"

RSpec.describe Communication::Constituents::MarketingCloud::Interactors::ImportInteractionFromCsv do
  describe "#call" do
    let(:csv_contents) do
      [
        ["..header"],
        [
          "de-1", "2359872", "0035I000007WSKbQAO", "23598724404", "Outbound",
          "24/09/2020 08:00:43", nil, nil, "DE_DE_CM_EM_DC_DCUpdateIPWDay27", "4404",
          "24/09/2020 08:00:43", "unsubscribed", nil, nil, "510001991",
          "DE_DE_CM_EM_DC_DCUpdateIPWDay27Camp", "email", "user unsub", "24/09/2020 08:00:43"
        ],
        [
          "", "2359872", "0035I000007WSKbQAO", "12345", "Outbound",
          "24/09/2020 08:00:43", nil, nil, "DE_DE_CM_EM_DC_DCUpdateIPWDay27", "4404",
          "24/09/2020 08:00:43", "unsubscribed", nil, nil, "510001991",
          "DE_DE_CM_EM_DC_DCUpdateIPWDay27Camp", "email", "user unsub", "24/09/2020 08:00:43"
        ]
      ]
    end
    let(:expected_interactions) do
      [
        {
          type: "Interaction::Email",
          mandate_id: "1",
          admin_id: 1,
          direction: "out",
          content: "DE_DE_CM_EM_DC_DCUpdateIPWDay27",
          metadata: {
            identifier: "DE_DE_CM_EM_DC_DCUpdateIPWDay27Camp",
            email_name: "DE_DE_CM_EM_DC_DCUpdateIPWDay27",
            delivered_at: "24/09/2020 08:00:43",
            bounced_at: "24/09/2020 08:00:43",
            bounced_type: "unsubscribed",
            primary_key: "23598724404",
            title: "DE_DE_CM_EM_DC_DCUpdateIPWDay27",
            bounced_reason: "user unsub",
            import_file_id: 1,
            created_by_robo: false
          }
        }
      ]
    end

    context "when valid marketing_cloud_import is passed in" do
      before do
        allow_any_instance_of(
          Communication::Constituents::MarketingCloud::Repositories::MarketingCloudImportRepository
        ).to receive(:read_marketing_cloud_import_file).and_return(csv_contents)
        allow_any_instance_of(
          Communication::Constituents::MarketingCloud::Repositories::MarketingCloudImportRepository
        ).to receive(:bot_admin_id).and_return(1)
      end

      it "parse and import interactions from csv" do
        expect_any_instance_of(
          Communication::Constituents::MarketingCloud::Repositories::MarketingCloudImportRepository
        ).to receive(:bulk_insert_interactions!).with(expected_interactions)
        expect_any_instance_of(
          Communication::Constituents::MarketingCloud::Repositories::MarketingCloudImportRepository
        ).to receive(:mark_import_as_completed).with(1)
        expect_any_instance_of(Raven::Instance).to receive(
          :capture_message
        ).with(
          "[WARNING] Marketing Cloud Interaction CSV contains invalid interactions",
          level: "warning",
          extra: {
            omitted_interactions_count: 1,
            invalid_interactions_primary_keys: ["12345"],
            marketing_cloud_import_id: 1
          }
        )

        subject.call(1)
      end
    end
  end
end
