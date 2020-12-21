# frozen_string_literal: true

require "rails_helper"

RSpec.describe Communication::Constituents::MarketingCloud::Interactors::ProcessImportedFiles do
  describe "#call" do
    context "when pending marketing_cloud_import exists" do
      let(:marketing_cloud_import) { double(:marketing_cloud_import, id: 707) }

      before do
        allow_any_instance_of(
          Communication::Constituents::MarketingCloud::Repositories::MarketingCloudImportRepository
        ).to receive(:pending_marketing_cloud_imports).and_return([marketing_cloud_import])
      end

      it "schedule ProcessImportedFileJob with marketing_cloud_id.id" do
        assert_enqueued_with(
          job: ::Communication::Jobs::ProcessImportedFileJob,
          args: [marketing_cloud_import.id],
          queue: "marketing_cloud_import"
        ) do
          subject.call
        end
      end
    end
  end
end
