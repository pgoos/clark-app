# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::UsersController, :integration, type: :controller do
  let(:role)  { create(:role, permissions: Permission.where(controller: "admin/users")) }
  let(:admin) { create(:admin, role: role) }

  before { login_admin(admin) }

  #
  # Settings
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Concerns
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Filter
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Actions
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  # TODO: REMOVE!
  it "makes the tests work since for some weird reason the first test is not logged in" do
    expect(1).to be(1)
  end

  context "#confirm" do
    let!(:user) { create(:user, confirmed_at: nil, confirmation_sent_at: 1.minute.ago, mandate: create(:mandate)) }

    it "manually sets the confirmed_at flag for the user" do
      patch :confirm, params: {id: user, locale: :de}
      expect(response).to redirect_to(admin_mandate_path(user.mandate))

      user.reload
      expect(user).to be_confirmed
    end

    it "manually sets the confirmed_at flag for the user (even if the confirmation mail was never sent)" do
      user.update_attributes(confirmation_sent_at: nil)

      patch :confirm, params: {id: user, locale: :de}
      expect(response).to redirect_to(admin_mandate_path(user.mandate))

      user.reload
      expect(user).to be_confirmed
    end

    it "manually sets the confirmed_at flag for the user (even if the confirmation mail was sent before devises threshold)" do
      confirmation_date = DateTime.now - User.confirm_within - 1.day
      user.update_attributes(confirmation_sent_at: confirmation_date)

      patch :confirm, params: {id: user, locale: :de}
      expect(response).to redirect_to(admin_mandate_path(user.mandate))

      user.reload
      expect(user).to be_confirmed
    end
  end

  context "#unconfirm" do
    let!(:user) { create(:user, confirmed_at: DateTime.now, mandate: create(:mandate)) }

    it "manually removes the confirmation" do
      patch :unconfirm, params: {id: user, locale: :de}
      expect(response).to redirect_to(admin_mandate_path(user.mandate))

      user.reload
      expect(user).not_to be_confirmed
    end
  end

  context "#subscribe" do
    let!(:user) { create(:user, confirmed_at: DateTime.now, subscriber: false, mandate: create(:mandate)) }

    it "manually subscribes the user" do
      patch :subscribe, params: {id: user, locale: :de}
      expect(response).to redirect_to(admin_mandate_path(user.mandate))

      user.reload
      expect(user.subscriber).to be_truthy
    end
  end

  context "#unconfirm" do
    let!(:user) { create(:user, confirmed_at: DateTime.now, subscriber: true, mandate: create(:mandate)) }

    it "manually un-subscribes the user" do
      patch :unsubscribe, params: {id: user, locale: :de}
      expect(response).to redirect_to(admin_mandate_path(user.mandate))

      user.reload
      expect(user.subscriber).to be_falsey
    end
  end

  describe "PATCH /activate" do
    let(:user) { create :user, state: :inactive }
    let(:logger) { double.as_null_object }

    before do
      allow(Rails).to receive(:logger).and_return(logger)
      allow(logger).to receive(:info)

      patch :activate, params: {locale: I18n.locale, id: user.id}
    end

    it { expect(user.reload.state).to eq "active" }
    it { expect(logger).to have_received(:info).with("User #{user.email} was set to active") }
    it { is_expected.to redirect_to(admin_user_path) }
    it { is_expected.to use_after_action(:log_event) }
    it { is_expected.to set_flash[:notice] }
  end

  describe "PATCH /deactivate" do
    let(:user) { create :user, state: :active }
    let(:logger) { double.as_null_object }

    before do
      allow(Rails).to receive(:logger).and_return(logger)
      allow(logger).to receive(:info)

      patch :deactivate, params: {locale: I18n.locale, id: user.id}
    end

    it { expect(user.reload.state).to eq "inactive" }
    it { expect(logger).to have_received(:info).with("User #{user.email} was set to inactive") }
    it { is_expected.to use_after_action(:log_event) }
    it { is_expected.to redirect_to(admin_user_path) }
    it { is_expected.to set_flash[:notice] }
  end

  describe "PATCH /reset_payout_data" do
    let!(:user) { create(:user, confirmed_at: DateTime.now, mandate: create(:mandate), paid_inviter_at: Time.zone.now) }

    it "clears reset payout data" do
      patch :reset_payout_data, params: {id: user, locale: :de}
      expect(response).to redirect_to(admin_user_path(user))

      user.reload
      expect(user.paid_inviter_at).to be_nil
    end
  end
end
