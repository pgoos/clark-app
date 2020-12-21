# frozen_string_literal: true

require "rails_helper"

describe OutboundChannels::DistributionChannels do
  let(:options) { {key: "offer_generated"} }

  after do
    Settings.reload!
  end

  it "raises an error if initialized with a settings key that doesn't exist" do
    expect {
      described_class.new(key: "non_existing")
    }.to raise_error("no settings associated to such key")
  end

  describe ".build_sms_from_push_data" do
    let(:mandate) { create(:mandate) }
    let(:valid_push_data) { PushService.build_transactional_push(mandate, "offer_available_top_price") }
    let(:sms_data) { described_class.build_sms_from_push_data(valid_push_data) }
    let!(:phone) { create(:phone, mandate: mandate, primary: true) }

    before do
      allow(Comfy::Cms::Site).to receive_message_chain(:find_by, :hostname).and_return("fake_host")
    end

    it "maps sms mandate to the push data mandate" do
      expect(sms_data[:mandate]).to eq(valid_push_data[:mandate])
    end

    it "maps sms topic to the push data topic" do
      expect(sms_data[:topic]).to eq(valid_push_data[:topic])
    end

    it "maps sms admin to the push data admin" do
      expect(sms_data[:admin]).to eq(valid_push_data[:admin])
    end

    it "maps sms phone to the push data mandate phone" do
      expect(sms_data[:phone_number]).to eq(phone.number)
    end

    it "maps sms content to push data content and a generated link from push clark url" do
      sms_link = valid_push_data[:clark_url]
      expect(sms_data[:content])
        .to eq("#{valid_push_data[:content]} #{Platform::UrlShortener.new.url_with_host(sms_link)}")
    end
  end

  describe "#build_and_deliver" do
    let(:subject) { described_class.new(options).build_and_deliver }

    let(:message) { object_double Interaction::Message.new, pushed_to_messenger: false }

    before do
      allow_any_instance_of(described_class).to receive(:mail).and_return(false)
      allow_any_instance_of(described_class).to receive(:push_with_sms_fallback).and_return(false)
      allow_any_instance_of(described_class).to receive(:push).and_return(false)
      allow_any_instance_of(described_class).to receive(:sms).and_return(false)
      allow_any_instance_of(described_class).to receive(:messenger).and_return(message)
    end

    context "mail" do
      after do
        Settings.reload!
      end

      it "calls mail method when mail setting is set to true" do
        Settings.transactional_messaging.offer_generated.email = true
        expect_any_instance_of(described_class).to receive(:mail)
        subject
      end

      it "doesn't call mail method when mail setting is set to false" do
        Settings.transactional_messaging.offer_generated.email = false
        expect_any_instance_of(described_class).not_to receive(:mail)
        subject
      end
    end

    context "push_with_sms_fallback" do
      after do
        Settings.reload!
      end

      it "calls push_with_sms_fallback method push_with_sms_fallback mail setting is set to true" do
        Settings.transactional_messaging.offer_generated.push_with_sms_fallback = true
        expect_any_instance_of(described_class).to receive(:push_with_sms_fallback)
        subject
      end

      it "doesn't call push_with_sms_fallback method when push_with_sms_fallback setting is set to false" do
        Settings.transactional_messaging.offer_generated.push_with_sms_fallback = false
        expect_any_instance_of(described_class).not_to receive(:push_with_sms_fallback)
        subject
      end
    end

    context "push" do
      after do
        Settings.reload!
      end

      it "calls push method when push setting is set to true and push_with_sms is false" do
        Settings.transactional_messaging.offer_generated.push_with_sms_fallback = false
        Settings.transactional_messaging.offer_generated.push = true
        expect_any_instance_of(described_class).to receive(:push)
        subject
      end

      it "doesn't call push method when push setting is set to false" do
        Settings.transactional_messaging.offer_generated.push = false
        expect_any_instance_of(described_class).not_to receive(:push)
        subject
      end

      it "doesn't call push method when push setting is set to true but push_with_sms is also true" do
        Settings.transactional_messaging.offer_generated.push_with_sms_fallback = true
        Settings.transactional_messaging.offer_generated.push = true
        expect_any_instance_of(described_class).not_to receive(:push)
        subject
      end
    end

    context "sms" do
      after do
        Settings.reload!
      end

      it "calls sms method when sms setting is set to true and push_with_sms is false" do
        Settings.transactional_messaging.offer_generated.push_with_sms_fallback = false
        Settings.transactional_messaging.offer_generated.sms = true
        expect_any_instance_of(described_class).to receive(:sms)
        subject
      end

      it "doesn't call sms method when sms setting is set to false" do
        Settings.transactional_messaging.offer_generated.sms = false
        expect_any_instance_of(described_class).not_to receive(:sms)
        subject
      end

      it "doesn't call sms method when sms setting is set to true but push_with_sms is also true" do
        Settings.transactional_messaging.offer_generated.push_with_sms_fallback = true
        Settings.transactional_messaging.offer_generated.sms = true
        expect_any_instance_of(described_class).not_to receive(:sms)
        subject
      end

      it "doesn't invoke sms method if MESSAGE_ONLY feature switch is active" do
        Settings.transactional_messaging.offer_generated.push_with_sms_fallback = false
        Settings.transactional_messaging.offer_generated.sms = true

        allow(Features).to receive(:active?).with(Features::MESSAGE_ONLY).and_return(true)

        expect_any_instance_of(described_class).not_to receive(:sms)
        subject
      end
    end

    context "messenger" do
      after do
        Settings.reload!
      end

      it "calls messenger method when messenger setting is set to true" do
        Settings.transactional_messaging.offer_generated.messenger = true
        expect_any_instance_of(described_class).to receive(:messenger)
        subject
      end

      it "doesn't call messenger method when messenger setting is set to false" do
        Settings.transactional_messaging.offer_generated.messenger = false
        expect_any_instance_of(described_class).not_to receive(:messenger)
        subject
      end
    end

    context "when message has been successfully delivered in messenger" do
      let(:message) { object_double Interaction::Message.new, pushed_to_messenger: true }

      after do
        Settings.reload!
      end

      it "does not send sms and push" do
        Settings.transactional_messaging.offer_generated.email = true
        Settings.transactional_messaging.offer_generated.messenger = true
        Settings.transactional_messaging.offer_generated.sms = true
        Settings.transactional_messaging.offer_generated.push = true

        expect_any_instance_of(described_class).to receive(:mail)
        expect_any_instance_of(described_class).to receive(:messenger)
        expect_any_instance_of(described_class).not_to receive(:push)
        expect_any_instance_of(described_class).not_to receive(:sms)

        subject
      end
    end
  end

  describe "#mail" do
    let(:subject) { described_class.new(options) }
    let(:dummy_mail) { double("mail") }
    let(:mailer_class) { OfferMailer }
    let(:mailer_method) { :offer_available_top_price }

    before do
      allow(mailer_class).to receive(mailer_method).and_return(dummy_mail)
      allow(dummy_mail).to receive(:deliver_now)
      allow(dummy_mail).to receive(:deliver_later)
    end

    after do
      Settings.reload!
    end

    it "fetches the mailer class and method from instance options and calls the mail delivery method" do
      options[:mailer_options] = {
        class: mailer_class.name,
        method: mailer_method.to_s
      }
      expect(mailer_class).to receive(mailer_method)
      subject.send(:mail)
    end

    it "overrides from options on the current settings for the mailer class and method" do
      Settings.transactional_messaging.offer_generated.mailer_options.class = "SomeClass"
      Settings.transactional_messaging.offer_generated.mailer_options.method = "someMethod"
      options[:mailer_options] = {
        class: mailer_class.name,
        method: mailer_method.to_s
      }
      expect(mailer_class).to receive(mailer_method)
      subject.send(:mail)
    end

    it "falls back to the settings if no options for mailer class and method are passed" do
      Settings.transactional_messaging.offer_generated.mailer_options.class = mailer_class.name
      Settings.transactional_messaging.offer_generated.mailer_options.method = mailer_method.to_s
      expect(mailer_class).to receive(mailer_method)
      subject.send(:mail)
    end

    it "calls the mailer with the arguments passed in mailer_options params" do
      options[:mailer_options] = {
        class: mailer_class.name,
        method: mailer_method.to_s,
        params: [1, 2, 3]
      }
      expect(mailer_class).to receive(mailer_method).with(1, 2, 3)
      subject.send(:mail)
    end

    it "calls the mailer method with deliver_now if it is set to true in instance options" do
      options[:mailer_options] = {
        class: mailer_class.name,
        method: mailer_method.to_s,
        deliver_now: true
      }
      expect(mailer_class).to receive_message_chain(mailer_method, :deliver_now)
      subject.send(:mail)
    end

    it "calls the mailer method with deliver_now if it is set to true in settings" do
      Settings.transactional_messaging.offer_generated.mailer_options.deliver_now = true
      options[:mailer_options] = {
        class: mailer_class.name,
        method: mailer_method.to_s
      }
      expect(mailer_class).to receive_message_chain(mailer_method, :deliver_now)
      subject.send(:mail)
    end

    it "overrides deliver_now option from options over the settings value" do
      Settings.transactional_messaging.offer_generated.mailer_options.deliver_now = false
      options[:mailer_options] = {
        class: mailer_class.name,
        method: mailer_method.to_s,
        deliver_now: true
      }
      expect(mailer_class).to receive_message_chain(mailer_method, :deliver_now)
      subject.send(:mail)
    end
  end

  describe "#messenger" do
    let(:subject) { described_class.new(options) }
    let(:messenger_class) { OutboundChannels::Messenger::TransactionalMessenger }
    let(:messenger_method) { :offer_available }
    let(:messenger_params) { [double("offer")] }

    before do
      allow(messenger_class).to receive(messenger_method).and_return(true)
    end

    after do
      Settings.reload!
    end

    it "fetches the messenger class and method from instance options and calls the messenger delivery method" do
      options[:messenger_options] = {
        class: messenger_class.name,
        method: messenger_method.to_s,
        params: messenger_params
      }
      expect(messenger_class).to receive(messenger_method)
      subject.send(:messenger)
    end

    it "overrides from options on the current settings for the mailer class and method" do
      Settings.transactional_messaging.offer_generated.messenger_options.class = "SomeClass"
      Settings.transactional_messaging.offer_generated.messenger_options.method = "someMethod"
      options[:messenger_options] = {
        class: messenger_class.name,
        method: messenger_method.to_s,
        params: messenger_params
      }
      expect(messenger_class).to receive(messenger_method)
      subject.send(:messenger)
    end

    it "falls back to the settings if no options for mailer class and method are passed" do
      options[:messenger_options] = {
        params: messenger_params
      }
      Settings.transactional_messaging.offer_generated.messenger_options.class = messenger_class.name
      Settings.transactional_messaging.offer_generated.messenger_options.method = messenger_method.to_s
      expect(messenger_class).to receive(messenger_method)
      subject.send(:messenger)
    end

    it "calls the messenger with the arguments passed in messenger_options params" do
      options[:messenger_options] = {
        class: messenger_class.name,
        method: messenger_method.to_s,
        params: messenger_params
      }
      expect(messenger_class).to receive(messenger_method).with(*messenger_params)
      subject.send(:messenger)
    end
  end

  describe "#push" do
    let(:device) { create(:device) }
    let(:mandate) { create(:mandate, user: create(:user, devices: [device])) }
    let(:subject) { described_class.new(options) }
    let(:push_params) { [mandate, "offer_available_top_price"] }

    before do
      allow(PushService).to receive(:send_transactional_push).and_return(true)
    end

    it "calls the push service send method when push data is valid" do
      options[:push_options] = {
        params: push_params
      }
      expect(PushService).to receive(:send_transactional_push)
      subject.send(:push)
    end

    it "doesn't call send push method if no push data were passed" do
      expect(PushService).not_to receive(:send_transactional_push)
      subject.send(:push)
    end
  end

  describe "#push_with_sms_fallback" do
    let(:mandate) { create(:mandate) }
    let(:subject) { described_class.new(options) }
    let(:valid_push_params) { [mandate, "offer_available_top_price"] }
    let(:valid_sms_data) {
      {
        mandate: mandate,
        topic: "topic",
        content: "content",
        phone_number: "01234567890",
        admin: Admin.bot
      }
    }

    before do
      allow_any_instance_of(OutboundChannels::PushWithSmsFallback).to receive(:send_message).and_return(true)
      allow(Comfy::Cms::Site).to receive_message_chain(:find_by, :hostname).and_return("fake_host")
    end

    it "doesn't call the send message method if push data is not passed in the options" do
      expect_any_instance_of(OutboundChannels::PushWithSmsFallback).not_to receive(:send_message)
      subject.send(:push_with_sms_fallback)
    end

    it "calls the send message method if valid push data passed in the options" do
      options[:push_options] = {
        params: valid_push_params
      }
      expect_any_instance_of(OutboundChannels::PushWithSmsFallback).to receive(:send_message)
      subject.send(:push_with_sms_fallback)
    end

    it "calculates the push and sms data from push params" do
      options[:push_options] = {
        params: valid_push_params
      }
      push_data = PushService.build_transactional_push(*valid_push_params)
      calculated_sms_data = described_class.build_sms_from_push_data(push_data)
      expect_any_instance_of(OutboundChannels::PushWithSmsFallback).to receive(:send_message).with(
        push_data, calculated_sms_data
      )
      subject.send(:push_with_sms_fallback)
    end

    it "overrides the sms data with the one that was a passed in the instance options" do
      options[:push_options] = {
        params: valid_push_params
      }
      options[:sms_options] = {
        data: valid_sms_data
      }
      push_data = PushService.build_transactional_push(*valid_push_params)
      expect_any_instance_of(OutboundChannels::PushWithSmsFallback).to receive(:send_message).with(
        push_data, valid_sms_data
      )
      subject.send(:push_with_sms_fallback)
    end
  end

  describe "#sms" do
    let(:mandate) { create(:mandate) }
    let(:subject) { described_class.new(options) }
    let(:valid_push_params) { [mandate, "offer_available_top_price"] }
    let(:valid_sms_data) {
      {
        mandate: mandate,
        topic: "topic",
        content: "content",
        phone_number: "01234567890",
        admin: Admin.bot
      }
    }

    before do
      allow_any_instance_of(Domain::Interactions::SmsDispatcher).to receive(:dispatch).and_return(true)
      allow(Domain::Interactions::SmsDispatcher).to receive(:new).and_call_original
      allow(Comfy::Cms::Site).to receive_message_chain(:find_by, :hostname).and_return("fake_host")
    end

    it "calculates the sms data from push data" do
      options[:push_options] = {
        params: valid_push_params
      }
      push_data = PushService.build_transactional_push(*valid_push_params)
      calculated_sms_data = described_class.build_sms_from_push_data(push_data)
      expect(Domain::Interactions::SmsDispatcher).to receive(:new).with(
        calculated_sms_data
      )
      subject.send(:sms)
    end

    it "overrides the sms data with the one that was a passed in the instance options" do
      options[:push_options] = {
        params: valid_push_params
      }
      options[:sms_options] = {
        data: valid_sms_data
      }
      expect(Domain::Interactions::SmsDispatcher).to receive(:new).with(
        valid_sms_data
      )
      subject.send(:sms)
    end
  end
end
