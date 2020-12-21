# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::Admin::V1::Messenger::Messages, :integration do
  let(:admin) { create(:admin, role: create(:role)) }

  before do
    login_as(admin, scope: :admin)
  end

  describe "POST /api/admin/messenger/:mandate_id/messages" do
    let(:mandate) { create :mandate }

    before do
      allow(Features).to receive(:active?).and_return true
      allow(Features).to receive(:active?).with(Features::MESSENGER).and_return true

      allow(OutboundChannels::Messenger::MessageRelay).to receive(:pass_message)
    end

    context "with text message" do
      it "creates a text message and sends it to the customer" do
        json_admin_post_v1 "/api/admin/messenger/#{mandate.id}/messages", content: "BLA BLA", message_type: "text"

        expect(response.status).to eq 201
        message = mandate.interactions.last

        expect(OutboundChannels::Messenger::MessageRelay).to \
          have_received(:pass_message).with(message, push_with_sms_fallback: true)
        expect(message.admin).to eq admin
        expect(message.content).to eq "BLA BLA"
        expect(message.message_type).to eq "text"
        expect(json_response["id"]).to eq message.id.to_s
      end
    end

    context "with rate us message" do
      it "creates a rate us message and sends it to the customer" do
        json_admin_post_v1 "/api/admin/messenger/#{mandate.id}/messages", message_type: "rate_us"

        expect(response.status).to eq 201
        message = mandate.interactions.last

        expect(OutboundChannels::Messenger::MessageRelay).to \
          have_received(:pass_message).with(message, push_with_sms_fallback: true)
        expect(message.admin).to eq admin
        expect(message.content).to be_present
        expect(message.message_type).to eq "rate_us"
      end
    end

    context "with link message" do
      let(:linkable) { create :product, mandate: mandate }

      it "creates a link message and sends it to the customer" do
        json_admin_post_v1 "/api/admin/messenger/#{mandate.id}/messages",
                           message_type: "link",
                           linkable_type: linkable.class.name,
                           linkable_id: linkable.id

        expect(response.status).to eq 201
        message = mandate.interactions.last

        expect(OutboundChannels::Messenger::MessageRelay).to \
          have_received(:pass_message).with(message, push_with_sms_fallback: true)
        expect(message.admin).to eq admin
        expect(message.message_type).to eq "link"
        expect(message.linkable_type).to eq "Product"
        expect(message.linkable_id).to eq linkable.id
      end

      context "without linkable param" do
        it "responds with validation error" do
          json_admin_post_v1 "/api/admin/messenger/#{mandate.id}/messages", content: "BLA BLA", message_type: "link"

          expect(response.status).to eq 400
        end
      end

      context "when linkable entity does not relate to customer or inactive" do
        let(:linkable) { create :product }

        it "responds with an error" do
          json_admin_post_v1 "/api/admin/messenger/#{mandate.id}/messages",
                             message_type: "link",
                             linkable_type: linkable.class.name,
                             linkable_id: linkable.id

          expect(response.status).to eq 401
        end
      end
    end

    context "when messenger feature is turned off" do
      before do
        allow(Features).to receive(:active?).with(Features::MESSENGER).and_return false
      end

      it "responds with an error" do
        json_admin_post_v1 "/api/admin/messenger/#{mandate.id}/messages", content: "BLA BLA", message_type: "text"

        expect(response.status).to eq 401
      end
    end

    context "when current admin is not assigned on mandate's message stream" do
      before do
        create :interaction_message, direction: "in", admin: create(:admin), acknowledged: false, mandate: mandate
      end

      it "responds with an error" do
        json_admin_post_v1 "/api/admin/messenger/#{mandate.id}/messages", content: "BLA BLA", message_type: "text"

        expect(response.status).to eq 401
      end
    end

    context "when message interactions are not allowed for specified mandate" do
      let(:mandate) { create :mandate, :owned_by_n26 }

      it "responds with an error" do
        json_admin_post_v1 "/api/admin/messenger/#{mandate.id}/messages", content: "BLA BLA", message_type: "text"

        expect(response.status).to eq 401
      end
    end
  end
end
