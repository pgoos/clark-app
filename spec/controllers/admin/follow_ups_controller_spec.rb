# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::FollowUpsController, :integration, type: :controller do
  let(:role)  { create(:role, permissions: Permission.where(controller: "admin/follow_ups")) }
  let(:admin) { create(:admin, role: role) }
  let(:mandate) { create(:mandate) }

  before { sign_in(admin) }

  describe "GET #index" do
    let!(:unacknowledged_followup) { create(:follow_up, :unacknowledged, admin: admin, item: mandate) }
    let!(:acknowledged_followup) { create(:follow_up, :acknowledged, item: mandate) }

    context "without any filter params" do
      it "should fetch only unacknowledged follow_ups by default" do
        get :index, params: {locale: :de}

        expect(assigns(:follow_ups).map(&:id)).to eq([unacknowledged_followup.id])
      end
    end

    context "with by_acknowledged param" do
      it "should only fetch unacknowledged follow_ups if by_acknowledged param is true" do
        get :index, params: {locale: :de, by_acknowledged: "true"}

        expect(assigns(:follow_ups).map(&:id)).to eq([acknowledged_followup.id])
      end
    end

    context "with by_admin_id param" do
      it "should only fetch follow_ups that assigned to that admin" do
        get :index, params: {locale: :de, by_admin_id: admin.id}

        expect(assigns(:follow_ups).map(&:id)).to eq([unacknowledged_followup.id])
      end
    end
  end

  describe "PATCH acknowledge" do
    let(:follow) { create :follow_up }

    before { patch :acknowledge, params: {locale: :de, id: follow.id} }

    it "makes follow acknowledged" do
      expect(follow.reload).to be_acknowledged
      expect(response).to redirect_to admin_root_path
    end
  end

  describe "GET calendar_event" do
    let(:follow_up) { create :follow_up, item: item }
    let(:item)      { mandate }
    let(:mandate)   { create :mandate }

    before do
      get :calendar_event, params: {locale: :de, id: follow_up.id}
    end

    it "sends calendar event" do
      body = normalize_response(response.body)
      expect(body).to include "BEGIN:VCALENDAR"
      expect(body).to include admin_work_items_url(anchor: "my_follow_ups")
      expect(response.header["Content-Type"]).to eq "text/calendar"
    end

    context "with opportunity" do
      let(:item) { create :shallow_opportunity, mandate: mandate }

      it "sends calendar event" do
        body = normalize_response(response.body)
        expect(body).to include "BEGIN:VCALENDAR"
        expect(body).to include admin_opportunity_url(item)
        expect(response.header["Content-Type"]).to eq "text/calendar"
      end
    end
  end

  def normalize_response(body)
    body.split("\n").map(&:strip).join("").tr("\r", "")
  end
end
