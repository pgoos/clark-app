require 'rails_helper'

describe Marketing::BehaviorService do
  let(:clark_campaign_1) { 'ClarkCampaign 1' }
  let(:clark_campaign_2) { 'ClarkCampaign 2' }
  let(:user_behavior_service) { Marketing::BehaviorService }

  context 'regular users' do
    let(:mandate) { create(:mandate) }
    let(:user) { create(:user, mandate: mandate) }

    it 'should return the initial touch tracking source for the first campaign, if it is available via tracking visit' do
      create(:tracking_visit, user: user, utm_source: clark_campaign_1)
      expect(user_behavior_service.first_touch_source(mandate)).to eq(clark_campaign_1)
    end

    it 'should return the initial touch tracking source for the second campaign, if it is available via tracking visit' do
      create(:tracking_visit, user: user, utm_source: clark_campaign_2)
      expect(user_behavior_service.first_touch_source(mandate)).to eq(clark_campaign_2)
    end

    it 'should return the initial touch tracking source for the first campaign, if it is available via adjust' do
      user.source_data = {'adjust' => {'network' => clark_campaign_1}}
      user.save!
      expect(user_behavior_service.first_touch_source(mandate)).to eq(clark_campaign_1)
    end

    it 'should raise an error, if it is a dangling mandate' do
      dangling_mandate = create(:mandate)
      expect {
        user_behavior_service.first_touch_source(dangling_mandate)
      }.to raise_error("Dangling mandate! ID: '#{dangling_mandate.id}'")
    end
  end

  context 'leads' do
    let(:lead_mandate) { create(:mandate) }
    let(:lead) { create(:lead, mandate: lead_mandate) }

    it 'should return the initial touch tracking source for the first campaign, if it is available via adjust' do
      lead.source_data = {'adjust' => {'network' => clark_campaign_1}}
      lead.save!
      expect(user_behavior_service.first_touch_source(lead_mandate)).to eq(clark_campaign_1)
    end

    it 'should not return the traffic source of a user, that has accidentially the same id as a lead' do
      wrong_user = create(:user, id: lead.id)
      create(:tracking_visit, user: wrong_user, utm_source: clark_campaign_2)
      expect(user_behavior_service.first_touch_source(lead_mandate)).to_not eq(clark_campaign_2)
    end
  end
end