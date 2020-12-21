# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::CandidateSelection::MandateSelection do
  include Domain::CandidateSelection::MandateSelection

  let(:audit_person) { create(:admin) }
  let(:mandate_selected) { create(:mandate) }
  let(:mandate_not_selected) { create(:mandate) }
  let(:action) { "accept" }

  let(:be_for_mandate_selected) do
    BusinessEvent.create(person:     audit_person,
                         entity:     mandate_selected,
                         action:     action,
                         metadata:   {},
                         created_at: 25.hours.ago)
  end

  let(:be_for_mandate_not_selected) do
    BusinessEvent.create(person:   audit_person,
                         entity:   mandate_not_selected,
                         action:   action,
                         metadata: {})
  end

  context "#mandates_accepted_older_than_24hago" do
    before do
      be_for_mandate_selected
      be_for_mandate_not_selected
      @available_mandates = mandates_accepted_older_than_24hago
    end

    it "expect mandate_selected to be present" do
      expect(@available_mandates).to include(mandate_selected.id)
    end

    it "expect mandate_not_selected not to be present" do
      expect(@available_mandates).not_to include(mandate_not_selected.id)
    end
  end
end
