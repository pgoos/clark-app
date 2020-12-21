# frozen_string_literal: true

require "rails_helper"
require "composites/customer/repositories/visits_repository"

RSpec.describe Customer::Repositories::VisitsRepository, :integration do
  subject(:repo) { described_class.new }

  describe "#find" do
    it "returns nil if there is no visit" do
      not_in_database_id = 111
      visit = repo.find(not_in_database_id)

      expect(visit).to be_nil
    end

    it "returns a visit entity" do
      visit = create(:tracking_visit)

      visit_entity = repo.find(visit.id)

      %i[
        id
        visitor_id
        ip
        referrer
        landing_page
        utm_source
        utm_medium
        utm_term
        utm_content
        utm_campaign
      ].each do |attribute|
        entity_value = visit_entity.send(attribute)
        ar_value = visit.send(attribute)

        expect(entity_value).to eq(ar_value)
      end
    end
  end
end
