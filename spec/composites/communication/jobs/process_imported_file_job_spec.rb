# frozen_string_literal: true

require "rails_helper"

RSpec.describe Communication::Jobs::ProcessImportedFileJob, :integeration do
  describe "#perform" do
    context "when marketing_cloud_import file is passed in" do
      let!(:admin) { create(:admin) }
      let!(:mandate) { create(:mandate, id: 8) }
      let!(:marketing_cloud_import) { create(:marketing_cloud_import) }

      it "imports interactions from the file" do
        expect {
          described_class.perform_now(marketing_cloud_import.id)
        }.to change {
          Interaction::Email.where(mandate: mandate, content: "email_name", direction: "out").count
        }.from(0).to(1)
      end
    end
  end
end
