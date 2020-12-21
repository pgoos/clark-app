# frozen_string_literal: true

require "rails_helper"
require "composites/salesforce/repositories/events/payloads/customer_demand_check_completed_repository"

RSpec.describe Salesforce::Repositories::Events::Payloads::CustomerDemandCheckCompleted do
  include RecommendationsSpecHelper

  subject(:repository) { described_class.new }

  let!(:user) { create(:user, last_sign_in_at: DateTime.current) }
  let!(:voucher) { create(:voucher) }
  let!(:mandate) { create(:mandate, :accepted, user: user, voucher_id: voucher.id) }
  let(:bedarfcheck_questionnaire) { create(:bedarfscheck_questionnaire) }
  let(:questionnaire_response) do
    create(:questionnaire_response, mandate: mandate, questionnaire: bedarfcheck_questionnaire, state: "analyzed")
  end

  before do
    create_question_with_answer("demand_number_of_kids", "2", questionnaire_response)
    create_question_with_answer("demand_job", "Selbstständiger", questionnaire_response)
  end

  describe "#wrap" do
    it "returns customer accepted event" do
      event = repository.wrap(mandate)
      expect(event.id).to eq mandate.id
      expect(event.country).to eq "de"
      expect(event.first_name).to eq mandate.first_name
      expect(event.last_name).to eq mandate.last_name
      expect(event.birthdate).to eq mandate.birthdate.strftime("%Y-%m-%d")
      expect(event.gender).to eq mandate.gender
      expect(event.email).to eq mandate.email
      expect(event.last_sign_in_at).to eq user.last_sign_in_at.rfc3339
      expect(event.subscriber).to eq mandate.subscriber?
      expect(event.push_enabled).to eq mandate.pushable_devices?
      expect(event.phone_number).to be_nil
      expect(event.street_and_number).to eq "#{mandate.address.street}, #{mandate.address.house_number}"
      expect(event.zip).to eq mandate.address.zipcode
      expect(event.confirmed_at).not_to be_nil
      expect(event.created_at).to eq mandate.created_at.rfc3339
      expect(event.voucher_id).to eq mandate.voucher_id.to_s
      expect(event.state).to eq mandate.state
      expect(event.gross_income).to be_nil
      expect(event.marital_status).to eq ""
      expect(event.number_of_children).to eq 2
      expect(event.job_title).to eq("")
      expect(event.job_situation).to eq "Selbstständiger"
      expect(event.house_building_planned).to eq ""
      expect(event).to be_kind_of Salesforce::Entities::Events::CustomerDemandCheckCompleted
    end

    context "when event does not exist" do
      it "returns nil" do
        expect(repository.wrap(nil)).to be_nil
      end
    end
  end
end
