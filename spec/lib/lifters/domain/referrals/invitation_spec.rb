# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Referrals::Invitation do
  subject { described_class.new(email: email, referrer: referrer) }

  let(:referral_code) { "sample_referral_code" }
  let(:referrer_mandate) { create(:mandate, :accepted) }

  context "when email is valid" do
    let(:email) { "test@test.clark.de" }

    context "when referrer is present" do
      let(:referrer) { create(:user, mandate: referrer_mandate, referral_code: referral_code) }

      context "when email does not belong to an existing user" do
        it { expect { subject.perform }.to change { ActionMailer::Base.deliveries.count }.by(1) }

        it "should store the invitation mail" do
          expect {
            subject.perform
          }.to change {
            referrer_mandate.documents.where(document_type: DocumentType.invite).count
          }.by(1)
        end

        context "with admin", :business_events do
          let(:action) { described_class::BUSINESS_EVENT_MAIL_ACTION }
          let(:key) { described_class::BUSINESS_EVENT_MAIL_KEY }

          before do
            create(:admin)
            subject.perform
          end

          it "should create a business event with the invited person's mail address" do
            event = BusinessEvent.find_by(entity: referrer, action: action)
            expect(event.metadata[key]).to eq(email)
          end

          it "provides a finder method for the business event" do
            event = described_class.find_invitation_event(email)
            expect(event.metadata[key]).to eq(email)
          end
        end
      end

      context "when email belongs to the referrer" do
        let(:referrer) { create(:user, mandate: referrer_mandate, email: email, referral_code: referral_code) }

        before { allow(User).to receive(:find_by).with(email: email).and_return(build_stubbed :user) }

        it { expect { subject.perform }.not_to change { ActionMailer::Base.deliveries.count } }
        it { expect { subject.perform }.to change { subject.errors.full_messages.count }.from(0).to(1) }
        it do
          subject.perform
          expect(subject.errors.messages[:email].first).to eq(I18n.t("already_taken_by_you"))
        end
      end

      context "when email belongs to another existing user" do
        before { allow(User).to receive(:find_by).with(email: email).and_return(build_stubbed :user) }

        it { expect { subject.perform }.not_to change { ActionMailer::Base.deliveries.count } }
        it { expect { subject.perform }.to change { subject.errors.full_messages.count }.from(0).to(1) }
        it do
          subject.perform
          expect(subject.errors.messages[:email].first).to eq(I18n.t("already_taken"))
        end
      end

    end

    context "when referrer is not present" do
      let(:referrer) { nil }

      it { expect { subject.perform }.to change { ActionMailer::Base.deliveries.count }.by(0) }
      it { expect { subject.perform }.to change { subject.errors.full_messages.count }.from(0).to(1) }
    end

  end

  context "when email is invalid" do
    let(:email) { "abc@#$#$% ffg" }

    context "when referrer is present" do
      let(:referrer) { create(:user, mandate: referrer_mandate, referral_code: referral_code) }

      it { expect { subject.perform }.to change { ActionMailer::Base.deliveries.count }.by(0) }
      it { expect { subject.perform }.to change { subject.errors.full_messages.count }.from(0).to(1) }
    end

    context "when referrer is not present" do
      let(:referrer) { nil }

      it { expect { subject.perform }.to change { ActionMailer::Base.deliveries.count }.by(0) }
      it { expect { subject.perform }.to change { subject.errors.full_messages.count }.from(0).to(2) }
    end
  end

  describe ".inject_referer_in_user" do
    let(:referral_code) { "1234" }
    let(:referrer) { create(:user, referral_code: referral_code) }
    let(:user) { create(:user) }

    it "does not inject the referrer if no referral code was passed" do
      expect(user).not_to receive(:invited_by)
      described_class.inject_referer_in_user(user, nil)
    end

    it "calls the invited by method on passed user" do
      expect(user).to receive(:invited_by).with(referrer, referral_code)
      described_class.inject_referer_in_user(user, referral_code)
    end
  end
end
