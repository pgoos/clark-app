require "rails_helper"

RSpec.describe Platform::PhoneVerification do
  let(:fake_token) { "1234" }
  let(:valid_phone) { "+4933322224444" }
  let(:invalid_phone) { "bananas" }

  let(:mandate) { create(:mandate) }
  let!(:user) { create(:user, mandate: mandate) }
  let(:subject) { described_class.new(mandate) }
  let(:subject_fake_token) { described_class.new(mandate, fake_token) }
  let!(:admin) { create(:admin) }

  context "#create_sms_verification" do
    context "successfull" do
      it "returns true with good phone" do
        expect(subject.create_sms_verification(valid_phone)).to eq(true)
      end

      it "if user has a phone and regenerated token" do
        subject.create_sms_verification(valid_phone)

        expect(subject.create_sms_verification(valid_phone)).to eq(true)
      end

      it "has different generated tokens when regenerated" do
        subject.create_sms_verification(valid_phone)
        first_token = Phone.primary(mandate).first.verification_token

        subject.create_sms_verification(valid_phone)
        second_token = Phone.primary(mandate).first.verification_token

        expect(second_token).not_to eq(first_token)
      end

      it "updates mandate phone" do
        subject.create_sms_verification(valid_phone)

        mandate.reload
        expect(mandate.phone).to eq(valid_phone)
      end

      it "gives the phone a token and a token_created_at" do
        time = Time.zone.local(1987)
        Timecop.freeze(time)

        subject.create_sms_verification(valid_phone)
        phone = Phone.primary(mandate).first

        expect(phone.token_created_at).to eq(time)
        expect(phone.verification_token).to eq(subject.token)
      end

      it "sends the sms" do
        msg = "Dein Clark-Bestätigungscode lautet #{fake_token}"
        expect_any_instance_of(OutboundChannels::Sms).to receive(:send_sms).with(valid_phone, msg, anything)

        subject_fake_token.create_sms_verification(valid_phone)
      end
    end

    context "failure" do
      it "with bad phone" do
        expect(subject.create_sms_verification(invalid_phone)).to eq(false)
      end

      it "does not updated the bad phone" do
        expect(mandate.phone).not_to eq(invalid_phone)
      end

      it "does not update an empty phone string" do
        expect(subject.create_sms_verification("")).to eq(false)
      end

      it "does not notify Sentry for an empty phone string" do
        expect(Raven).not_to receive(:capture_exception)
        subject.create_sms_verification("")
      end

      it "does not update phone being nil" do
        expect(subject.create_sms_verification(nil)).to eq(false)
      end

      it "does not notify Sentry for phone being nil" do
        expect(Raven).not_to receive(:capture_exception)
        subject.create_sms_verification(nil)
      end
    end

    context "when customer belongs to partner" do
      let(:mandate) { create :mandate, owner_ident: "partner" }

      it "sends the sms" do
        msg = "Dein Clark-Bestätigungscode lautet #{fake_token}"
        expect_any_instance_of(OutboundChannels::Sms).to receive(:send_sms).with(valid_phone, msg, anything)

        subject_fake_token.create_sms_verification(valid_phone)
      end
    end
  end

  context "#verify_token" do
    let(:valid_token) { fake_token }
    let(:invalid_token) { "2345" }

    before do
      subject_fake_token.create_sms_verification(valid_phone)
    end

    it "is valid with right token" do
      expect(subject_fake_token.verify_token(valid_token)).to eq(true)
    end

    context "when mandate has customer state" do
      let(:mandate) { create(:mandate, customer_state: "self_service") }

      it "emits event" do
        expect_any_instance_of(Utils::EventEmitter::Emit)
          .to receive(:call)
          .with("customer_signed_mandate", mandate.id)
        subject_fake_token.verify_token(valid_token)
      end
    end

    context "when mandate does not have customer state" do
      it "does not emit event" do
        expect_any_instance_of(Utils::EventEmitter::Emit)
          .not_to receive(:call)
          .with("customer_signed_mandate", mandate.id)
        subject_fake_token.verify_token(valid_token)
      end
    end

    it "is not valid with wrong token" do
      expect(subject_fake_token.verify_token(invalid_token)).to eq(false)
    end

    it "resets the validation token" do
      subject_fake_token.verify_token(invalid_token)

      phone = Phone.primary(mandate).first

      expect(phone.verified_at).to eq(nil)
    end

    it "is not valid with right token after 5 minutes" do
      Timecop.freeze(6.minutes.from_now)
      expect(subject_fake_token.verify_token(valid_token)).to eq(false)
    end
  end
end
