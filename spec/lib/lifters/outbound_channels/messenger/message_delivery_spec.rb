# frozen_string_literal: true

require "rails_helper"
require "lifters/outbound_channels/mocks/fake_remote_push_client"

RSpec.describe OutboundChannels::Messenger::MessageDelivery, type: :integration do
  let(:user)    { create(:user, :with_mandate) }
  let(:admin)   { create(:admin) }
  let(:content) { Faker::Lorem.characters(number: 50) }
  let(:device)  { create(:device) }
  let(:subject) { described_class.new(content, user.mandate, admin) }

  before do
    allow(Features).to receive(:active?).and_return(false)
    allow(Features).to receive(:active?).with(Features::MESSENGER).and_return(true)
    site = double :site, hostname: "localhost"
    allow(Comfy::Cms::Site).to receive(:find_by).with(identifier: "de").and_return site
  end

  describe "#send_message" do
    it "creates a message interaction no matter what" do
      expect { subject.send_message }.to change { Interaction::Message.count }.by(1)
    end

    it "creates a message interaction with the content given" do
      subject.send_message
      expect(Interaction::Message.last.content).to eq(content)
    end

    it "creates a message interaction with out direction" do
      subject.send_message
      expect(Interaction::Message.last.direction).to eq(Interaction.directions[:out])
    end

    it "does not do a socket push if the feature switch is off" do
      allow(Features).to receive(:active?).with(Features::MESSENGER).and_return(false)
      device.update(user: user)
      class_instance = subject
      expect(class_instance).not_to receive(:push_with_sms_fallback)
      class_instance.send_message
    end

    it "passes the metadata to the created object" do
      metadata = {
        identifier:      "messenger.example",
        created_by_robo: true,
        cta_text:        "messenger.example.cta_text",
        cta_link:        "messenger.example.cta_link",
        cta_section:     "messenger.example.cta_section"
      }

      subject_with_metadata =  described_class.new(content, user.mandate, admin, metadata)
      subject_with_metadata.send_message

      expect(Interaction::Message.last.identifier).to      eq(metadata[:identifier])
      expect(Interaction::Message.last.created_by_robo).to eq(metadata[:created_by_robo])
      expect(Interaction::Message.last.cta_text).to        eq(metadata[:cta_text])
      expect(Interaction::Message.last.cta_link).to        eq(metadata[:cta_link])
      expect(Interaction::Message.last.cta_section).to     eq(metadata[:cta_section])
    end

    it "passes topic to the created object" do
      product = create(:product)
      subject_with_metadata = described_class.new(content, user.mandate, admin, {}, product)
      subject_with_metadata.send_message

      expect(product).to eq(product)
    end

    context "when socket is open" do
      before do
        socket_server_response = instance_double(
          Net::HTTPResponse,
          code: HTTP::Status::OK.to_s
        )

        allow_any_instance_of(OutboundChannels::Messenger::SocketDelivery)
          .to receive(:call)
          .with(any_args)
          .and_return(socket_server_response)
      end

      it "sets flag pushed_to_messenger if socket is open" do
        messenger = described_class.new(content, user.mandate, admin, {}, create(:product))
        message = messenger.send_message
        expect(message.pushed_to_messenger).to eq true
      end
    end

    describe "push message" do
      it "tries to do a socket push to the mandate if possible" do
        device.update(user: user)
        class_instance = subject
        expect(class_instance).to receive(:push_with_sms_fallback)
        class_instance.send_message
      end

      it "does not try push notification if disabled" do
        expect_any_instance_of(OutboundChannels::PushWithSmsFallback)
          .not_to receive(:send_message)
        expect(subject).not_to receive(:push_with_sms_fallback)
      end

      it "send push if user has device" do
        user.devices = [device]
        expect { subject.send_message }.to change { Interaction::PushNotification.count }.by(1)
      end

      describe "push content" do
        let(:subject_with_metadata) { described_class.new(content, user.mandate, admin, metadata) }

        let(:metadata) do
          {
            identifier: "messenger.example",
            created_by_robo: true,
            cta_text: "messenger.example.cta_text",
            cta_link: "messenger.example.cta_link",
            cta_section: "messenger.example.cta_section"
          }
        end

        before do
          socket_server_response = instance_double(
            Net::HTTPResponse,
            code: HTTP::Status::BAD_REQUEST.to_s
          )

          allow_any_instance_of(OutboundChannels::Messenger::SocketDelivery)
            .to receive(:call)
            .with(any_args)
            .and_return(socket_server_response)
          user.devices = [device]
        end

        it "creates a push notification if no socket is open and user has push enabled devices" do
          expect { subject_with_metadata.send_message }.to change { Interaction::PushNotification.count }.by(1)
        end

        it "does not set flag pushed_to_messenger if no socket is open" do
          message = subject_with_metadata.send_message
          expect(message.pushed_to_messenger).not_to eq true
        end

        it "not push notification withouth push enabled, when on fail" do
          user.devices = []
          expect { subject.send_message }.not_to(change { Interaction::PushNotification.count })
        end

        it "reuses the existing data / metadata, if no specific data for push is given" do
          subject_with_metadata.send_message
          push = Interaction::PushNotification.where(mandate: user.mandate).last

          expect(push.attributes).to include(
            "mandate_id" => user.mandate_id,
            "admin_id" => admin.id,
            "content" => content
          )
          expect(push.metadata).to include(
            "title" => I18n.t("messenger.phone_push_title"),
            "section" => "feed",
            "clark_url" => "/de/app/feed"
          )
        end

        it "reuses the existing data / metadata, if the value for push is given but no hash" do
          metadata[:push_data] = "value of wrong type"
          subject_with_metadata.send_message
          push = Interaction::PushNotification.where(mandate: user.mandate).last

          expect(push.attributes).to include(
            "mandate_id" => user.mandate_id,
            "admin_id" => admin.id,
            "content" => content
          )
          expect(push.metadata).to include(
            "title" => I18n.t("messenger.phone_push_title"),
            "section" => "feed",
            "clark_url" => "/de/app/feed"
          )
        end

        it "reuses the specific data / metadata, if given" do
          metadata[:push_data] = {
            title: "different #{rand}",
            content: "different content #{rand}"
          }
          subject_with_metadata.send_message
          push = Interaction::PushNotification.where(mandate: user.mandate).last

          expect(push.attributes).to include(
            "mandate_id" => user.mandate_id,
            "admin_id" => admin.id,
            "content" => metadata[:push_data][:content]
          )
          expect(push.metadata).to include(
            "title" => metadata[:push_data][:title],
            "section" => "feed",
            "clark_url" => "/de/app/feed"
          )
        end

        it "reuses the specific data / metadata, if given also with string keys" do
          metadata["push_data"] = {
            "title" => "different #{rand}",
            "content" => "different content #{rand}"
          }
          subject_with_metadata.send_message
          push = Interaction::PushNotification.where(mandate: user.mandate).last

          expect(push.attributes).to include(
            "mandate_id" => user.mandate_id,
            "admin_id" => admin.id,
            "content" => metadata["push_data"]["content"]
          )
          expect(push.metadata).to include(
            "title" => metadata["push_data"]["title"],
            "section" => "feed",
            "clark_url" => "/de/app/feed"
          )
        end
      end
    end

    context "when falling back to SMS" do
      let(:sample_cta_link) { "/sample/link" }
      let(:short_link) { "https://host:port/short" }
      let(:sample_cta_link_fall_back) { "/de/app/manager" }
      let(:short_link_fallback) { "https://host:port/short_fallback" }
      let(:metadata) do
        {
          identifier:      "messenger.example",
          created_by_robo: true,
          cta_text:        "messenger.example.cta_text",
          cta_link:        sample_cta_link,
          cta_section:     "messenger.example.cta_section"
        }
      end

      before do
        allow(Platform::UrlShortener)
          .to receive_message_chain(:new, :url_with_host)
          .with("/de" + sample_cta_link)
          .and_return(short_link)
        allow(Platform::UrlShortener)
          .to receive_message_chain(:new, :url_with_host)
          .with(sample_cta_link_fall_back)
          .and_return(short_link_fallback)
      end

      it "should send the sms with the cta link" do
        subject_with_metadata = described_class.new(content, user.mandate, admin, metadata)
        expect_any_instance_of(OutboundChannels::PushWithSmsFallback)
          .to receive(:send_message)
          .with(Hash, hash_including(content: "#{content} #{short_link}"))
        subject_with_metadata.send_message
      end

      it "should fall back to /de/app/manager, if no cta_link is given" do
        metadata.delete(:cta_link)
        subject_with_metadata = described_class.new(content, user.mandate, admin, metadata)
        expect_any_instance_of(OutboundChannels::PushWithSmsFallback)
          .to receive(:send_message)
          .with(Hash, hash_including(content: "#{content} #{short_link_fallback}"))
        subject_with_metadata.send_message
      end
    end

    context "robo advised" do
      let(:metadata) do
        {
          identifier:      "messenger.example",
          created_by_robo: true,
          cta_text:        "messenger.example.cta_text",
          cta_link:        "messenger.example.cta_link",
          cta_section:     "messenger.example.cta_section"
        }
      end

      it "falls back to sms on robo advisor messages" do
        subject_with_metadata = described_class.new(content, user.mandate, admin, metadata)
        expect_any_instance_of(OutboundChannels::PushWithSmsFallback).to receive(:send_message)
        subject_with_metadata.send_message
      end

      it "does not fallback if it is not robo advisor messages" do
        non_robo_metadata = metadata.merge(created_by_robo: false)
        expect_any_instance_of(OutboundChannels::PushWithSmsFallback).to receive(:send_message).with(Hash, nil)

        subject_with_metadata = described_class.new(content, user.mandate, admin, non_robo_metadata)
        subject_with_metadata.send_message
      end
    end
  end
end
