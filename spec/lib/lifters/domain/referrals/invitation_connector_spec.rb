# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Referrals::InvitationConnector do
  let(:action) { Domain::Referrals::Invitation::BUSINESS_EVENT_MAIL_ACTION }
  let(:mail_key) { Domain::Referrals::Invitation::BUSINESS_EVENT_MAIL_KEY }

  let(:inviter) { instance_double(User) }
  let(:invited_mail) { "successful.invitation@clark.de" }
  let(:invited_user) { instance_double(User, email: invited_mail) }
  let(:invitation_event) { instance_double(BusinessEvent, entity: inviter) }

  let(:other_mail) { "not.invited@clark.de" }
  let(:other_user) { instance_double(User, email: other_mail) }

  let(:invitation_class) { Domain::Referrals::Invitation }

  it "should connect a referring mandate to the invited person" do
    allow(invitation_class)
      .to receive(:find_invitation_event)
      .with(invited_mail)
      .and_return(invitation_event)

    expect(invited_user).to receive(:update_attributes!).with(inviter: inviter)

    described_class.after_create(invited_user)
  end

  it "should not do anything, if user not siging up via invitation" do
    allow(invitation_class)
      .to receive(:find_invitation_event)
      .with(other_mail)
      .and_return(nil)

    expect(other_user).not_to receive(:update_attributes!)

    described_class.after_create(other_user)
  end
end
