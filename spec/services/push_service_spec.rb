# frozen_string_literal: true

require "rails_helper"

RSpec.describe PushService do
  context "transactional push" do
    let(:device) { create(:device) }
    let(:mandate) {
      create(:mandate, user: create(:user, devices: [device]))
    }

    context "push action" do
      before do
        expect(Aws::SNS::Client).not_to receive(:new)
      end

      it "creates an interaction with the given attributes" do
        expect { PushService.send_transactional_push(mandate, "reminder") }
          .to change { mandate.interactions.count }.by(1)
      end

      it "user or lead is not assigned to mandate" do
        mandate.update!(user: nil)
        expect {
          PushService.send_transactional_push(mandate, "reminder")
        }.not_to change(mandate.interactions, :count)
      end

      it "does not push if the mandate belongs to Clark partner" do
        mandate.update!(owner_ident: "clark_partner_ident")
        expect {
          PushService.send_transactional_push(mandate, "reminder")
        }.not_to change(mandate.interactions, :count)
      end

      it "sends push to malburg customer" do
        mandate.update!(owner_ident: "malburg")
        expect {
          PushService.send_transactional_push(mandate, "reminder")
        }.to change(mandate.interactions, :count)
      end

      it "does not push if the mandate has no devices with push" do
        allow(mandate).to receive_message_chain("user_or_lead.devices.with_push_enabled").and_return([])

        expect {
          PushService.send_transactional_push(mandate, "reminder")
        }.not_to change(mandate.interactions, :count)
      end

      it "does not push if translation is missing" do
        allow(I18n).to(
          receive(:exists?)
            .with("transactional_push.reminder")
            .and_return(false)
        )

        expect {
          PushService.send_transactional_push(mandate, "reminder")
        }.not_to change(mandate.interactions, :count)
      end
    end

    describe "#remote_service" do
      let(:user) { create(:user, email: "fabs@clark.de") }
      let(:mandate_clark) { create(:mandate, user: user) }

      context "returns fake service" do
        it "in case empty mandate is passed" do
          allow(Rails.env).to receive(:development?).and_return(true)

          expect(described_class.send(:remote_client, nil))
            .to eq(OutboundChannels::Mocks::FakeRemotePushClient)
        end

        it "in development" do
          allow(Rails.env).to receive(:development?).and_return(true)

          expect(described_class.send(:remote_client, mandate))
            .to eq(OutboundChannels::Mocks::FakeRemotePushClient)
        end

        it "in staging" do
          allow(Rails.env).to receive(:staging?).and_return(true)

          expect(described_class.send(:remote_client, mandate))
            .to eq(OutboundChannels::Mocks::FakeRemotePushClient)
        end

        it "in another staging" do
          allow(Rails.env).to receive(:staging2?).and_return(true)

          expect(described_class.send(:remote_client, mandate))
            .to eq(OutboundChannels::Mocks::FakeRemotePushClient)
        end

        it "in development even with @clark.de" do
          allow(Rails.env).to receive(:development?).and_return(true)

          expect(described_class.send(:remote_client, mandate_clark))
            .to eq(OutboundChannels::Mocks::FakeRemotePushClient)
        end
      end

      context "returns real service" do
        it "in production" do
          allow(Rails.env).to receive(:production?).and_return(true)

          expect(described_class.send(:remote_client, mandate))
            .to be_a(Aws::SNS::Client)
        end

        it "in staging with @clark.de" do
          allow(Rails.env).to receive(:staging?).and_return(true)
          allow(Rails.env).to receive(:development?).and_return(false)
          allow(Rails.env).to receive(:test?).and_return(false)

          expect(described_class.send(:remote_client, mandate_clark))
            .to be_a(Aws::SNS::Client)
        end
      end
    end
  end

  context "Push text" do
    # Checks whether correct file is picked up for Push notifications text when in Clark context
    context "Clark" do
      before do
        allow(Core::Context).to receive(:running).and_return(Core::Context.clark)
      end

      it "reads the push strings from correct file" do
        expect(I18n.t("transactional_push.notification_available.title")).to eq("Clark")
      end
    end
  end

  describe "#send_push_notification" do
    let(:arn) { "arn:aws:sns:eu-central-1:012345678910:app/GCM/app_android_Production/5e3e9847" }
    let(:device) { create(:device, permissions: { push_enabled: true }, arn: arn, token: "FOO_TOKEN") }
    let(:device_no_permission) { create(:device, permissions: { push_enabled: false }) }
    let(:mandate_with_device) { create(:mandate, user: create(:user, devices: [device])) }
    let(:mandate_with_no_permission_device) { create(:mandate, user: create(:user, devices: [device_no_permission])) }
    let(:mandate_without_device) { create(:mandate) }

    before do
      platform_arn = "arn:aws:sns:eu-central-1:012345678910:app/GCM/app_android_Production"
      allow(Device).to receive(:platform_arn).with(device).and_return(platform_arn)
    end

    it "stores the devices it actually sent to in the interaction" do
      devices = described_class.send_push_notification(mandate_with_device, "title", "content")
      expect(devices).to match_array([device])
    end

    it "does not send out notification to devices with no permission" do
      devices = described_class.send_push_notification(mandate_with_no_permission_device, "title", "content")
      expect(devices).to match_array([])
    end

    it "does not send out notification mandates with no device" do
      devices = described_class.send_push_notification(mandate_without_device, "title", "content")
      expect(devices).to match_array([])
    end

    context "when user is inactive" do
      before { allow(mandate_with_device).to receive_message_chain(:user, :inactive?).and_return(true) }

      it "does not send notification" do
        devices = described_class.send_push_notification(mandate_with_device, "title", "content")
        expect(devices).to match_array([])
      end
    end

    context "when arn endpoint doesn't exist anymore" do
      before do
        allow(OutboundChannels::Mocks::FakeRemotePushClient).to \
          receive(:get_endpoint_attributes)
          .with(endpoint_arn: arn)
          .and_raise(Aws::SNS::Errors::NotFound.new({}, "msg"))
      end

      it "creates a new arn for device" do
        devices = described_class.send_push_notification(mandate_with_device, "title", "content")

        expect(devices).to match_array([device])
        expect(device.reload.arn).to be_present
        expect(device.arn).not_to eq(arn)
      end
    end

    context "when arn existing endpoint device token is changed" do
      let(:attr_response) do
        OutboundChannels::Mocks::FakeRemotePushClient::EndpointAttributesResponse
          .new("Token" => "BAR_TOKEN", "Enabled" => "true")
      end

      before do
        allow(OutboundChannels::Mocks::FakeRemotePushClient).to \
          receive(:get_endpoint_attributes)
          .with(endpoint_arn: arn)
          .and_return(attr_response)
      end

      it "does not create a new arn for device" do
        expect(OutboundChannels::Mocks::FakeRemotePushClient).to \
          receive(:set_endpoint_attributes)
          .with(
            endpoint_arn: arn,
            attributes: {"Enabled" => "true", "Token" => "FOO_TOKEN"}
          )

        devices = described_class.send_push_notification(mandate_with_device, "title", "content")

        expect(devices).to match_array([device])
        expect(device.reload.arn).to eq(arn)
      end
    end

    context "when arn existing endpoint is disabled" do
      let(:attr_response) do
        OutboundChannels::Mocks::FakeRemotePushClient::EndpointAttributesResponse
          .new("Token" => "FOO_TOKEN", "Enabled" => "false")
      end

      before do
        allow(OutboundChannels::Mocks::FakeRemotePushClient).to \
          receive(:get_endpoint_attributes)
          .with(endpoint_arn: arn)
          .and_return(attr_response)
      end

      it "does not create a new arn for device" do
        expect(OutboundChannels::Mocks::FakeRemotePushClient).to \
          receive(:set_endpoint_attributes)
          .with(
            endpoint_arn: arn,
            attributes: {"Enabled" => "true", "Token" => "FOO_TOKEN"}
          )

        devices = described_class.send_push_notification(mandate_with_device, "title", "content")

        expect(devices).to match_array([device])
        expect(device.reload.arn).to eq(arn)
      end
    end

    context "when arn existing endpoint is active" do
      let(:attr_response) do
        OutboundChannels::Mocks::FakeRemotePushClient::EndpointAttributesResponse
          .new("Token" => "FOO_TOKEN", "Enabled" => "true")
      end

      before do
        allow(OutboundChannels::Mocks::FakeRemotePushClient).to \
          receive(:get_endpoint_attributes)
          .with(endpoint_arn: arn)
          .and_return(attr_response)
      end

      it "does not create a new arn for device" do
        expect(OutboundChannels::Mocks::FakeRemotePushClient).not_to \
          receive(:set_endpoint_attributes)

        devices = described_class.send_push_notification(mandate_with_device, "title", "content")
        expect(devices).to match_array([device])

        expect(device.reload.arn).to eql arn
      end
    end

    context "when existing arn format is invalid" do
      before do
        allow(OutboundChannels::Mocks::FakeRemotePushClient).to \
          receive(:get_endpoint_attributes)
          .with(endpoint_arn: arn)
          .and_raise(Aws::SNS::Errors::InvalidParameter.new({}, "EndpointArn Reason: Bla bla bla"))
      end

      it "creates a new arn for device" do
        devices = described_class.send_push_notification(mandate_with_device, "title", "content")

        expect(devices).to match_array([device])
        expect(device.reload.arn).to be_present
        expect(device.arn).not_to eql arn
      end
    end

    context "when existing arn doesn't match platform arn" do
      let(:arn) { "arn:aws:sns:eu-central-1:109876543210:app/GCM/app_android_Production/5e3e9847" }

      it "creates a new arn for device" do
        devices = described_class.send_push_notification(mandate_with_device, "title", "content")

        expect(devices).to match_array([device])
        expect(device.reload.arn).to be_present
        expect(device.arn).not_to eq(arn)
      end
    end
  end

  describe "#send_and_save_interaction" do
    let(:arn) { "arn:aws:sns:eu-central-1:012345678910:app/GCM/app_android_Production/5e3e9847" }
    let(:device) { create(:device, permissions: { push_enabled: true }, arn: arn, token: "FOO_TOKEN") }
    let(:device_no_permission) { create(:device, permissions: {push_enabled: false}) }
    let(:mandate_with_device) { create(:mandate, user: create(:user, devices: [device])) }
    let(:interaction_with_device) { create(:interaction_push_notification, mandate: mandate_with_device) }
    let(:mandate_with_no_permission_device) { create(:mandate, user: create(:user, devices: [device_no_permission])) }
    let(:interaction_with_no_permission_device) do
      create(:interaction_push_notification, mandate: mandate_with_no_permission_device)
    end
    let(:interaction_without_device) { create(:interaction_push_notification) }

    before do
      platform_arn = "arn:aws:sns:eu-central-1:012345678910:app/GCM/app_android_Production"
      allow(Device).to receive(:platform_arn).with(device).and_return(platform_arn)
    end

    it "stores the devices it actually sent to in the interaction" do
      described_class.send_and_save_interaction(interaction_with_device)
      expect(interaction_with_device.reload.devices).to match_array([device.human_name])
      expect(interaction_with_device.delivered).to be true
    end

    it "does not send out notification to devices with no permission" do
      described_class.send_and_save_interaction(interaction_with_no_permission_device)
      expect(interaction_with_no_permission_device.reload.devices).to match_array([])
      expect(interaction_with_no_permission_device.delivered).to be false
    end

    it "does not send out notification mandates with no device" do
      described_class.send_and_save_interaction(interaction_without_device)
      expect(interaction_without_device.reload.devices).to match_array([])
      expect(interaction_without_device.delivered).to be false
    end

    context "when user is inactive" do
      before { allow(mandate_with_device).to receive_message_chain(:user, :inactive?).and_return(true) }

      it "does not send notification" do
        described_class.send_and_save_interaction(interaction_with_device)
        expect(interaction_with_device.reload.devices).to match_array([])
        expect(interaction_with_device.delivered).to be false
      end
    end
  end

  describe "published sns message content" do
    let(:arn) { "arn:aws:sns:eu-central-1:012345678910:app/GCM/app_android_Production/5e3e9847" }
    let(:device) { create(:device, permissions: { push_enabled: true }, arn: arn, token: "FOO_TOKEN", os: os) }
    let(:mandate) { create(:mandate, user: create(:user, devices: [device])) }
    let(:remote_client) { PushService.send(:remote_client, mandate) }
    let(:interaction) do
      create(
        :interaction_push_notification, mandate: mandate, created_by_robo_advisor: false, identifier: "mango"
      )
    end

    before do
      allow(Device).to receive(:platform_arn).with(device).and_return(arn)
    end

    context "ios" do
      let(:os) { "ios" }
      let(:expected_message) do
        {
          default: interaction.content,
          "APNS_SANDBOX": {
            aps: {
              alert: {
                :title           => interaction.title,
                "action-loc-key" => "Open",
                :body            => interaction.content,
                :clark_url       => interaction.clark_url,
                :section         => interaction.section,
                :metadata        => {
                  interactionID: interaction.id, sent_by_robo: false, interactionIdentifier: "mango"
                }
              },
              sound: "default",
              badge: 1
            }
          }.to_json
        }
      end

      it "pushes sns message to IOS with tracking metadata" do
        expect(remote_client).to receive(:publish).with(
          message: expected_message.to_json, target_arn: arn, message_structure: "json"
        )
        PushService.send_and_save_interaction(interaction, [device])
      end
    end

    context "android" do
      let(:os) { "android" }
      let(:expected_message) do
        {
          default: interaction.content,
          GCM: {
            data: {
              title:     interaction.title,
              message:   interaction.content,
              clark_url: interaction.clark_url,
              section:   interaction.section,
              metadata:  { interactionID: interaction.id, sent_by_robo: false, interactionIdentifier: "mango" }
            }
          }.to_json
        }
      end

      it "pushes sns message to IOS with tracking metadata" do
        expect(remote_client).to receive(:publish).with(
          message: expected_message.to_json, target_arn: arn, message_structure: "json"
        )
        PushService.send_and_save_interaction(interaction, [device])
      end
    end
  end

  describe ".ios_sns_message" do
    after { allow(Rails.env).to receive(:production?).and_call_original }

    context "when production env" do
      before { allow(Rails.env).to receive(:production?).and_return(true) }

      it "use APNS key in payload" do
        payload = described_class.send(:ios_sns_message, "title", "message")
        expect(payload.keys).to include(:APNS)
      end
    end

    context "when non production env" do
      before { allow(Rails.env).to receive(:production?).and_return(false) }

      it "use APNS_SANDBOX key in payload" do
        payload = described_class.send(:ios_sns_message, "title", "message")
        expect(payload.keys).to include(:APNS_SANDBOX)
      end
    end
  end
end
