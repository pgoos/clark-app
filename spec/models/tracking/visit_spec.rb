# == Schema Information
#
# Table name: tracking_visits
#
#  id               :uuid             not null, primary key
#  visitor_id       :uuid
#  ip               :string
#  user_agent       :text
#  referrer         :text
#  landing_page     :text
#  user_id          :integer
#  referring_domain :string
#  search_keyword   :string
#  browser          :string
#  os               :string
#  device_type      :string
#  screen_height    :integer
#  screen_width     :integer
#  country          :string
#  region           :string
#  city             :string
#  postal_code      :string
#  latitude         :decimal(, )
#  longitude        :decimal(, )
#  utm_source       :string
#  utm_medium       :string
#  utm_term         :string
#  utm_content      :string
#  utm_campaign     :string
#  started_at       :datetime
#  mandate_id       :integer
#

require 'rails_helper'

RSpec.describe Tracking::Visit, type: :model do

  let(:clark_campaign_1) { 'ClarkCampaign 1' }
  let(:mandate) { create(:mandate) }
  let(:user) { create(:user, mandate: mandate) }

  # Setup
  # ---------------------------------------------------------------------------------------

  # Settings
  # ---------------------------------------------------------------------------------------

  # Constants
  # ---------------------------------------------------------------------------------------

  # Attribute Settings
  # ---------------------------------------------------------------------------------------

  # Plugins
  # ---------------------------------------------------------------------------------------

  # Concerns
  # ---------------------------------------------------------------------------------------

  # State Machine
  # ---------------------------------------------------------------------------------------

  # Scopes
  # ---------------------------------------------------------------------------------------
  context 'ordered visits for a user' do

    before do
      @first_visit = create(:tracking_visit, user: user)
      create(:tracking_visit)
      @last_visit = create(:tracking_visit, user: user)
    end

    it 'should deliver visits from oldest to newest' do
      visits = Tracking::Visit.for_user_chronological(user)
      expect(visits.first.id).to eq(@first_visit.id)
    end

    it 'should deliver visits from newest to oldest' do
      visits = Tracking::Visit.for_user_inverse_chronological(user)
      expect(visits.first.id).to eq(@last_visit.id)
    end

    it 'should chronologically only deliver visits for the given user' do
      visits = Tracking::Visit.for_user_chronological(user)
      expect(visits.size).to eq(2)
    end

    it 'should inverse chronologically only deliver visits for the given user' do
      visits = Tracking::Visit.for_user_inverse_chronological(user)
      expect(visits.size).to eq(2)
    end
  end

  describe '.by_visitor_id' do
    subject { Tracking::Visit.by_visitor_id(visitor_id) }

    let(:visitor_id) { "ab123456-1abc-123a-ab12-ab0ab01a1a12" }
    let(:other_visitor_id) { "xy675386-1abc-123a-ab12-ab0ab01a1a12" }
    let(:tracking_visit) { create :tracking_visit, visitor_id: visitor_id }
    let(:other_tracking_visit) { create :tracking_visit, visitor_id: other_visitor_id }

    before 'create objects in DB' do
      tracking_visit && other_tracking_visit
    end

    it 'returns tracking visits with given visitor_id'  do
      expect(subject).to match_array([tracking_visit])
    end
  end

  include_examples 'between_scopeable', :started_at

  # Associations
  # ---------------------------------------------------------------------------------------

  it { expect(subject).to belong_to(:user) }
  it { expect(subject).to belong_to(:mandate) }

  # Nested Attributes
  # ---------------------------------------------------------------------------------------

  # Validations
  # ---------------------------------------------------------------------------------------

  # Callbacks
  # ---------------------------------------------------------------------------------------

  # Instance Methods
  # ---------------------------------------------------------------------------------------
  describe "#try_set_mandate_by_visitor_id_slowly" do
    subject{ visit.try_set_mandate_by_visitor_id_slowly }

    let(:visit) { create :tracking_visit, visitor_id: visitor_id, mandate: mandate }
    let(:visitor_id) { "ab123456-1abc-123a-ab12-ab0ab01a1a12" }

    context 'when visit has no mandate' do
      let(:mandate) { nil }

      context 'when another visit with same visitor_id exists' do
        before { create :tracking_visit, visitor_id: visitor_id, mandate: other_mandate }

        context 'when other visit has mandate' do
          let(:other_mandate) { create :mandate }

          it "sets the other mandate as the event's mandate" do
            expect{ subject }.to change{ visit.mandate }.from(nil).to(other_mandate)
          end
        end

        context 'when other visit has no mandate' do
          let(:other_mandate) { nil }

          it "sets the other mandate as the event's mandate" do
            expect{ subject }.not_to change{ visit.mandate }
          end
        end
      end

      context 'when another event with a visit with the same visitor_id' do
        before do
          other_visit = create :tracking_visit, visitor_id: visitor_id, mandate: nil
          create :tracking_event, visit_id: other_visit.id, mandate: other_mandate
        end

        context 'when other visit has mandate' do
          let(:other_mandate) { create :mandate }

          it "sets the other mandate as the event's mandate" do
            expect{ subject }.to change{ visit.mandate }.from(nil).to(other_mandate)
          end
        end

        context 'when other visit has no mandate' do
          let(:other_mandate) { nil }

          it "sets the other mandate as the event's mandate" do
            expect{ subject }.not_to change{ visit.mandate }
          end
        end
      end
    end

    context 'when event has mandate already' do
      let(:mandate) { create :mandate }

      # test only one of the many cases in which nothing should change now

      context 'when another visit with same visitor_id and mandate exists' do
        before { create :tracking_visit, visitor_id: visitor_id, mandate: other_mandate }
        let(:other_mandate) { create :mandate }

        it 'does not change the mandate' do
          expect{ subject }.not_to change{ visit.mandate }
        end
      end
    end
  end

  context 'utm source for a user' do
    it 'should return it, if it is there' do
      first_visit = create(:tracking_visit, user: user, utm_source: clark_campaign_1)
      create(:tracking_visit, user: user, utm_source: 'ClarkCampaign 2')
      expect(Tracking::Visit.first_touch_source(user)).to eq(first_visit.utm_source)
    end

    it 'should return nil, if there is nothing' do
      create(:tracking_visit, user: user, utm_source: nil)
      create(:tracking_visit, user: user, utm_source: 'ClarkCampaign 2')
      expect(Tracking::Visit.first_touch_source(user)).to be(nil)
    end

    it 'should return nil, if there are no traffic visits associated with the user' do
      expect(Tracking::Visit.first_touch_source(user)).to be(nil)
    end
  end

  # Class Methods
  # ---------------------------------------------------------------------------------------
end
