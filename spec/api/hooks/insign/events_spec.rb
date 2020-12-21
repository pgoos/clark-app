# frozen_string_literal: true

require "rails_helper"

RSpec.describe Hooks::Insign::Events, :integration do
  context "GET /events" do
    context "with signature_created event" do
      it "handles event" do
        expect_any_instance_of(Domain::Signatures::Handlers::SignatureCreated).to \
          receive(:process)
        get "/hooks/insign/events?sessionid=TEST&eventid=SIGNATURERSTELLT"
        expect(response.status).to eq 200
      end
    end

    context "with process_completed event" do
      it "handles event" do
        expect_any_instance_of(Domain::Signatures::Handlers::ProcessCompleted).to \
          receive(:process)
        get "/hooks/insign/events?sessionid=TEST&eventid=VORGANGABGESCHLOSSEN"
        expect(response.status).to eq 200
      end
    end

    context "with externbearbeitungfertig event" do
      it "does nothing" do
        get "/hooks/insign/events?externToken=TOKENN&eventid=EXTERNBEARBEITUNGFERTIG&sessionid=FOO"
        expect(response.status).to eq 200
      end
    end
  end
end
