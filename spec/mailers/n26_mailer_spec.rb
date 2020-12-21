# frozen_string_literal: true

require "rails_helper"

RSpec.describe N26Mailer, :integration, type: :mailer do
  let(:owner_ident) { "n26" }
  let(:state) { "accepted" }
  let(:mandate) { create(:mandate, :with_user, state: state, owner_ident: owner_ident) }
  let(:migration_token) { SecureRandom.urlsafe_base64(32, false) }

  describe "#migration_instructions" do
    let(:mail) { N26Mailer.migration_instructions(mandate, migration_token) }
    let(:documentable) { mandate }
    let(:document_type) { DocumentType.n26_migration_instructions }

    include_examples "checks mail rendering"
    include_examples "tracks document and mandate in ahoy email"
  end

  describe "#migration_welcome" do
    let(:mandate) { create(:mandate, :with_user, state: state) }
    let(:mail) { N26Mailer.migration_welcome(mandate) }
    let(:documentable) { mandate }
    let(:document_type) { DocumentType.n26_migration_welcome }

    include_examples "checks mail rendering"
    include_examples "tracks document and mandate in ahoy email"
  end

  describe "#migration_reminder" do
    let(:mail) { N26Mailer.migration_reminder(mandate, migration_token) }
    let(:documentable) { mandate }
    let(:document_type) { DocumentType.n26_migration_reminder }

    include_examples "checks mail rendering"
    include_examples "tracks document and mandate in ahoy email"
  end

  describe "#get_mandate" do
    context "when passing mandate model as argument" do
      it "returns mandate model" do
        expect(subject.send("get_mandate", mandate)).to eq mandate
      end
    end

    context "when passing mandate_id as argument" do
      it "finds and returns mandate model" do
        returned_mandate = subject.send("get_mandate", mandate.id)

        expect(returned_mandate).to be_kind_of Mandate
        expect(returned_mandate.id).to eq mandate.id
      end
    end

    context "When passing parameter which is not mandate nor mandate_id" do
      it "raises ArgumentError" do
        expect {
          subject.send("get_mandate", DocumentType.first)
        }.to raise_exception ArgumentError
      end
    end
  end
end
