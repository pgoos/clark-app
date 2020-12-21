# frozen_string_literal: true

require "rails_helper"

describe RoboAdvisor do
  subject { RoboAdvisor.new(logger) }

  let(:device)        { create(:device, push_enabled: true) }
  let(:user)          { create(:user, devices: [device]) }
  let(:mandate)       { create(:mandate, user: user) }
  let(:product)       { create(:product, mandate: mandate) }
  let(:other_product) { create(:product, mandate: mandate) }
  let(:logger)        { Logger.new("/dev/null") }

  before do
    RoboAdvisor::ADVICE_ADMIN_EMAILS.each do |email|
      create(:admin, email: email)
    end
    FeatureSwitch.create!(key: Features::ROBO_ADVISOR, active: true, limit: 1000)

    # We generally do not care about mails or pushes being sent out.
    # We check specifically where needed.
    allow(MandateMailer).to receive_message_chain("notification_available.deliver_now")
    allow(PushService).to receive(:send_push_notification)
                            .with(mandate, any_args).and_return([double(Device, human_name: "some iPhone")])
    allow(mandate).to receive(:pushable_devices?).and_return(true)
  end

  context "initialize" do
    context "robo advisor feature switch is turned off" do
      before do
        Features.turn_off_feature!(Features::ROBO_ADVISOR)
      end
      it "runs in dry run mode by default" do
        instance = RoboAdvisor.new(logger)
        expect(instance.dry_run).to be_truthy
      end

      it "runs in dry run mode even if specified as false" do
        instance = RoboAdvisor.new(logger, false)
        expect(instance.dry_run).to be_truthy
      end
    end

    context "robo advisor feature switch is turned on" do
      it "does not run in dry run mode by default" do
        instance = RoboAdvisor.new(logger)
        expect(instance.dry_run).to be_falsey
      end

      it "runs in dry run mode if specified as true" do
        instance = RoboAdvisor.new(logger, true)
        expect(instance.dry_run).to be_truthy
      end
    end
  end

  context ".run_intent_for_robo" do
    let(:product) { double(Product, last_advice: nil) }
    let(:attributes) { {content: "something"} }
    let(:advice) { double(Interaction::Advice) }

    it "creates an advice" do
      expect(subject.intent).to receive(:create_advice!).and_return(nil)

      subject.send(:run_intent_for_robo, product, attributes)
    end

    it "delivers when an interaction is created" do
      allow(subject.intent).to receive(:create_advice!).and_return(nil)

      expect(subject.send(:run_intent_for_robo, product, attributes)).to eq(0)
    end

    it "does not fail, and delivers when an interaction is not created" do
      allow(subject.intent).to receive(:create_advice!).and_return(advice)
      allow(advice).to receive(:notify_customer)
      allow(advice).to receive(:save!)

      expect(subject.send(:run_intent_for_robo, product, attributes)).to eq(1)
    end
  end

  context "questionnaire identifiers" do
    let(:private_liability_ident2) { "other_private_liability" }
    let(:private_liability_category) do
      instance_double(
        Category,
        questionnaire_identifier: nil
      )
    end

    let(:legal_ident2) { "other_legal_protection" }
    let(:legal_protection_category) do
      instance_double(
        Category,
        questionnaire_identifier: nil
      )
    end

    before do
      allow(Category).to receive(:phv).and_return(private_liability_category)
      allow(Category).to receive(:legal_protection).and_return(legal_protection_category)
    end

    it "should use the configured questionnaire identifier for phv if available" do
      allow(private_liability_category)
        .to receive(:questionnaire_identifier)
        .and_return(private_liability_ident2)
      expected_link = "/de/app/questionnaire/#{private_liability_ident2}"
      expect(described_class.phv_questionnaire_link).to  eq(expected_link)
    end
  end

  describe ".random_low_margin_admin" do
    context "when production" do
      before { allow(Rails).to receive(:env).and_return("production") }

      context "when ADVICE_ADMIN_EMAILS is set" do
        it "returns the admin based on the settings" do
          expect(RoboAdvisor::ADVICE_ADMIN_EMAILS).to include described_class.random_low_margin_admin.email
        end
      end

      context "when ADVICE_ADMIN_EMAILS is not set" do
        it "load admin based on id" do
          admin = create(:admin, id: 83)
          stub_const("RoboAdvisor::ADVICE_ADMIN_EMAILS", [])
          stub_const("RoboAdvisor::LOW_MARGIN_ADMIN", [83])

          expect(described_class.random_low_margin_admin).to eq admin
        end
      end
    end

    context "when not on production env" do
      let(:admin_double) { double(Admin) }

      before { allow(Admin).to receive(:first).and_return(admin_double) }

      it { expect(described_class.random_low_margin_admin).to eq admin_double }
    end
  end

  describe ".load_advice_admins" do
    context "when ADVICE_ADMIN_EMAILS is set" do
      it "loads admins based on ADVICE_ADMIN_EMAILS" do
        expect(described_class.load_advice_admins.pluck(:email)).to match RoboAdvisor::ADVICE_ADMIN_EMAILS
      end
    end

    context "when no users registered with settings' email" do
      it "loads admin based on ids" do
        admin = create(:admin, id: 83)
        stub_const("RoboAdvisor::ADVICE_ADMIN_EMAILS", [])
        stub_const("RoboAdvisor::ADVICE_ADMIN_IDS", [83])

        expect(described_class.load_advice_admins).to eq [admin]
      end
    end

    context "when no admins with settings email or ids" do
      it "lookup for Admin.first" do
        admin = Admin.first
        stub_const("RoboAdvisor::ADVICE_ADMIN_EMAILS", [])
        stub_const("RoboAdvisor::LOW_MARGIN_ADMIN", [])

        expect(described_class.load_advice_admins).to eq [admin]
      end
    end
  end

  describe ".load_high_margin_admins" do
    context "when HIGH_MARGIN_ADMIN_EMAILS is set" do
      it "loads admins based on HIGH_MARGIN_ADMIN_EMAILS" do
        admin = create(:admin, email: "alexander.schecher@clark.de")

        expect(described_class.load_high_margin_admins).to eq [admin]
      end
    end

    context "when no users registered with settings' email" do
      it "loads admin based on ids" do
        admin = create(:admin, id: 83)
        stub_const("RoboAdvisor::HIGH_MARGIN_ADMIN_EMAILS", [])
        stub_const("RoboAdvisor::HIGH_MARGIN_ADMIN", [83])

        expect(described_class.load_high_margin_admins).to eq [admin]
      end
    end

    context "when no admins with settings email or ids" do
      it "lookup for Admin.first" do
        admin = Admin.first
        stub_const("RoboAdvisor::HIGH_MARGIN_ADMIN_EMAILS", [])
        stub_const("RoboAdvisor::HIGH_MARGIN_ADMIN", [])

        expect(described_class.load_high_margin_admins).to eq [admin]
      end
    end
  end

  describe "#email_log" do
    let(:file_path) { "/" }
    let(:recipients) { ["user@example.com"] }
    let(:arguments) do
      {from: Settings.emails.service, to: recipients,
       subject: "CRON for Robo Advisor: #{file_path}", body: "siehe Attachment"}
    end
    let(:mail) { double.as_null_object }

    before do
      allow(ActionMailer::Base).to receive(:mail).with(arguments).and_return(mail)
      allow(mail).to receive(:deliver_now)
      allow(File).to receive(:read)

      described_class.new(logger).email_log(file_path, recipients)
    end

    it { expect(ActionMailer::Base).to have_received(:mail) }
    it { expect(mail).to have_received(:deliver_now) }
  end
end
