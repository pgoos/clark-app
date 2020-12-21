require 'rails_helper'


RSpec.describe ClarkAPI::V2::AnonymousLead, :integration do

  describe 'POST /api/anonymous_lead' do
    context 'when no user or lead is in session' do
      let(:adjust) { {network: 'some_source'} }
      it 'creates and returns a new anonymous lead' do
        json_post_v2 '/api/anonymous_lead'

        expect(response.status).to eq(201)
        expect(session['warden.user.lead.key']).to be_a_kind_of(Lead)
      end

      it 'creates and returns a new anonymous lead with source data' do
        json_post_v2('/api/anonymous_lead', {adjust: {network: "someSource", campaign: "someCampaign", creative: "someCreative"}})

        expect(response.status).to eq(201)
        expect(session['warden.user.lead.key']).to be_a_kind_of(Lead)
        expect(Lead.last.source_data["adjust"]["network"]).to eq("someSource")
        expect(Lead.last.source_data["adjust"]["campaign"]).to eq("someCampaign")
        expect(Lead.last.source_data["adjust"]["creative"]).to eq("someCreative")
      end

      it 'creates and returns a new anonymous lead with source data nil if params not present' do
        json_post_v2 '/api/anonymous_lead'

        expect(response.status).to eq(201)
        expect(session['warden.user.lead.key']).to be_a_kind_of(Lead)
        expect(Lead.last.source_data["adjust"]["network"]).to be_nil
        expect(Lead.last.source_data["adjust"]["campaign"]).to be_nil
        expect(Lead.last.source_data["adjust"]["creative"]).to be_nil
      end

    end

    context 'when user is in session' do
      before do
        user = create(:user, mandate: create(:mandate))
        login_as(user)
      end

      it 'does not create anonymous lead' do
        json_post_v2 '/api/anonymous_lead'

        expect(response.status).to eq(409)
      end
    end

    context 'when lead is in session' do
      before do
        lead = create(:lead, mandate: create(:mandate))
        login_as(lead, scope: :lead)
      end

      it 'does not create anonymous lead' do
        json_post_v2 '/api/anonymous_lead'

        expect(response.status).to eq(409)
      end
    end
  end
end

