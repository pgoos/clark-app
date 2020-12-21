# frozen_string_literal: true

require "rails_helper"
require "lifters/outbound_channels/mocks/fake_remote_sms_client"

RSpec.describe Admin::InteractionsController, :integration, type: :controller do
  let(:role)           { create(:role, permissions: Permission.where(controller: "admin/interactions")) }
  let(:some_admin)     { create(:admin, role: role) }
  let(:mandate)        { create(:mandate) }
  let(:sales_campaign) { create(:sales_campaign) }
  let!(:user)    { create(:user, mandate: mandate) }
  let!(:product) { create(:product, mandate: mandate) }

  include_context "inactive message only switch"

  before { login_admin(some_admin) }

  # Concerns
  # Filter
  # Actions
  # TODO this should be removed after figuring out why admin login is not working with out it
  it "makes the tests work since for some weird reason the first test is not logged in" do
    expect(1).to eq(1)
  end

  describe "GET index" do
    let(:mandate) { create :mandate }

    render_views

    it "responds with the list of interactions without layout" do
      interaction1 = create :interaction_email, mandate: mandate
      interaction2 = create :interaction_email

      get :index, params: {locale: I18n.locale, mandate_id: mandate.id}

      expect(response.body).to include "data-interaction=\'#{interaction1.id}\'"
      expect(response.body).not_to include "data-interaction=\'#{interaction2.id}\'"
    end

    it "filters interactions out by type" do
      interaction1 = create :interaction_email, mandate: mandate
      interaction2 = create :incoming_message, mandate: mandate

      get :index, params: {
        locale: I18n.locale,
        mandate_id: mandate.id,
        interaction_type: "Interaction::Message"
      }

      expect(response.body).not_to include "data-interaction=\'#{interaction1.id}\'"
      expect(response.body).to include "data-interaction=\'#{interaction2.id}\'"
    end
  end

  describe "POST create" do
    context "when interaction is Interaction::PhoneCall" do
      context "when valid arguments are passed in" do
        let(:valid_arguments) do
          {
            "direction" => "in",
            "content" => "Customer is busy now",
            "status" => "reached",
            "call_type" => "general",
            "sales_campaign_id" => sales_campaign.id
          }
        end

        it "creates Interaction::PhoneCall with SalesCampaign" do
          post :create, params: {
            locale: I18n.locale,
            product_id: product.id,
            interaction_phone_call: valid_arguments
          }

          expect(
            Interaction::PhoneCall.exists?(
              mandate_id: mandate.id,
              direction: :in,
              content: "Customer is busy now",
              sales_campaign_id: sales_campaign.id
            )
          ).to be_truthy
        end
      end
    end

    context "advice reply interaction (with deliver email checked)" do
      let(:valid_params) {
        {content: "advice reply", send_mail: "1"}
      }

      it "delivers an email when admin writes an advice reply" do
        mail_double = n_double("mail_double")
        expect(mail_double).to receive(:deliver_now)
        expect(MandateMailer).to receive(:advice_reply_notification)
          .with(product.mandate).and_return(mail_double)

        post :create, params: {locale: I18n.locale,
                               product_id: product.id,
                               interaction_advice_reply: valid_params}
      end

      it "delivers a push notification when admin writes an advice reply" do
        expect(PushService).to receive(:send_push_notification)

        post :create, params: {locale: I18n.locale,
                               product_id: product.id,
                               interaction_advice_reply: valid_params}
      end
    end

    context "advice reply interaction (without deliver email checked)" do
      let(:valid_params) {
        {content: "advice reply", send_mail: "0"}
      }

      it "does not deliver an email when admin writes an advice reply" do
        expect(MandateMailer).not_to receive(:advice_reply_notification)

        post :create, params: {locale: I18n.locale,
                               product_id: product.id,
                               interaction_advice_reply: valid_params}
      end

      it "does not deliver a push notification when admin writes an advice reply" do
        expect(PushService).not_to receive(:send_push_notification)

        post :create, params: {locale: I18n.locale,
                               product_id: product.id,
                               interaction_advice_reply: valid_params}
      end
    end

    context "sms interaction" do
      let(:valid_params)   { {content: "sms", phone_number: "1771912227"} }
      let(:invalid_params) { {content: "sms", phone_number: "911"} }

      before do
        Settings.sns.sandbox_disabled = false
      end

      after do
        Settings.reload!
      end

      it "sends the sms when creating a new sms interaction" do
        expect(OutboundChannels::Mocks::FakeRemoteSMSClient).to receive(:publish)
        expect {
          post :create, params: {locale: I18n.locale,
                                 product_id: product.id,
                                 interaction_sms: valid_params}
        }.to change(Interaction::Sms, :count).by(1)
      end

      it "will not send an sms if the interaction data is invalid" do
        expect(OutboundChannels::Mocks::FakeRemoteSNSClient).not_to receive(:publish)
        expect {
          post :create, params: {locale: I18n.locale,
                                 product_id: product.id,
                                 interaction_sms: invalid_params}
        }.not_to change(Interaction::Sms, :count)
      end

      it "will not save the sms interaction if any thing goes wrong sending the sms" do
        allow(OutboundChannels::Mocks::FakeRemoteSMSClient).to receive(:publish).and_raise("boom")
        expect {
          post :create, params: {locale: I18n.locale,
                                 product_id: product.id,
                                 interaction_sms: invalid_params}
        }.not_to change(Interaction::Sms, :count)
      end
    end

    context "message" do
      let(:valid_params) { {content: "message content"} }
      let(:mandate)      { create(:mandate) }
      let(:admin)        { create(:admin) }
      let(:content)      { Faker::Lorem.characters(number: 50) }

      before do
        allow(Features).to receive(:active?).with(Features::MESSENGER).and_return(true)
      end

      it "should not mark incoming unread messages as acknowledged after consultant replies" do
        unread_message = Interaction::Message.create!(
          content: content,
          mandate: mandate,
          admin: admin,
          direction: Interaction.directions[:in],
          acknowledged: false
        )

        post :create, params: { locale: I18n.locale,
                                mandate_id: mandate.id,
                                interaction_message: valid_params }

        expect(unread_message.reload.acknowledged). to eq(false)
      end

      context "with push notification" do
        let(:user) { create(:device_user) }
        let(:mandate) { create(:mandate, user: user) }

        before do
          create(:device, user: user)
          socketdelivery = double(:socket_delivery, call: nil)
          allow(OutboundChannels::Messenger::SocketDelivery).to receive(:new).and_return(socketdelivery)
        end

        it "sends push notification if web socket channel is not available" do
          params = { content: "###Rich-Text:{\"message\":\"Hier kommst du zu deinem Vertrag.\",\"ctaText\":\"Foo\"}###" }
          post :create, params: { locale: I18n.locale,
                                  mandate_id: mandate.id,
                                  interaction_message: params }

          messages = mandate.interactions.outgoing_messages
          push_notifications = Interaction::PushNotification.where(mandate: mandate)

          expect(messages.count).to eq 1
          expect(messages.first.content).to eq params[:content]
          expect(push_notifications.count).to eq 1
          expect(push_notifications.first.content).to eq "Hier kommst du zu deinem Vertrag."
        end
      end
    end

    context "manual product assesment" do
      let(:valid_params) do
        {
          interaction_advice: {
            content: Faker::Lorem.paragraph,
            cta_link: Faker::Internet.url,
            identifier: "keeper_switcher",
            manual_classification: "keeper"
          }
        }.merge(locale: I18n.locale, product_id: product.id)
      end

      context "when valid parameters are posted" do
        it "should create Interactive#Advice" do
          post :create, params: valid_params

          last_advice = Interaction::Advice.last

          expect(response).to have_http_status(:found)
          expect(last_advice.reoccurring_advice).to be(false)
          expect(last_advice.created_by_robo_advisor).to be(false)
          expect(last_advice.content).to eql(valid_params[:interaction_advice][:content])
          expect(last_advice.cta_link).to eql(valid_params[:interaction_advice][:cta_link])
          expect(last_advice.identifier).to eql(valid_params[:interaction_advice][:identifier])
          expect(last_advice.manual_classification).to eql(valid_params[:interaction_advice][:manual_classification])
        end
      end
    end
  end

  describe "PATCH mark_incoming_as_read" do
    let(:mandate) { create(:mandate) }
    let(:admin) { create(:admin) }
    let(:content) { Faker::Lorem.characters(number: 50) }

    it "marks every incoming unread interactions for a specific parent as read " \
       "when called without specifying a type" do
      unread_message1 = Interaction::Message.create!(
        content: content,
        mandate: mandate,
        admin: admin,
        direction: Interaction.directions[:in],
        acknowledged: false
      )

      unread_message2 = Interaction::Message.create!(
        content: content,
        mandate: mandate,
        admin: admin,
        direction: Interaction.directions[:in],
        acknowledged: false
      )

      patch :mark_incoming_as_read, params: {locale: I18n.locale,
                                             mandate_id: mandate.id,
                                             format: :js}
      expect(unread_message1.reload.acknowledged).to eq(true)
      expect(unread_message2.reload.acknowledged).to eq(true)
    end

    it "marks only the specified type for incoming unread interactions for a specific parent " \
       "as read when called with specifying a type" do
      unread_message1 = Interaction::Message.create!(
        content: content,
        mandate: mandate,
        admin: admin,
        direction: Interaction.directions[:in],
        acknowledged: false
      )

      unread_message2 = Interaction::AdviceReply.create!(
        content: content,
        mandate: mandate,
        topic: mandate,
        admin: admin,
        direction: Interaction.directions[:in],
        acknowledged: false
      )

      patch :mark_incoming_as_read, params: {locale: I18n.locale,
                                             mandate_id: mandate.id,
                                             type: Interaction::Message.name,
                                             format: :js}

      expect(unread_message1.reload.acknowledged).to eq(true)
      expect(unread_message2.reload.acknowledged).to eq(false)
    end

    it "marks incoming unread interactions for json format" do
      unread_message1 = Interaction::Message.create!(
        content: content,
        mandate: mandate,
        admin: admin,
        direction: Interaction.directions[:in],
        acknowledged: false
      )

      unread_message2 = Interaction::AdviceReply.create!(
        content: content,
        mandate: mandate,
        topic: mandate,
        admin: admin,
        direction: Interaction.directions[:in],
        acknowledged: false
      )

      patch :mark_incoming_as_read, params: {locale: I18n.locale,
                                             mandate_id: mandate.id,
                                             type: Interaction::Message.name,
                                             format: :json}

      expect(unread_message1.reload.acknowledged).to eq(true)
      expect(unread_message2.reload.acknowledged).to eq(false)
    end
  end

  describe "POST /send_rating_message" do
    let(:user) { create(:user, :with_mandate) }

    it "sends messenger message to clark users" do
      allow(Features).to receive(:active?).with(Features::MESSENGER).and_return(true)
      mandate_messages_query = Interaction::Message.where(mandate: user.mandate)
      expect {
        post :send_rating_message, params: {locale: I18n.locale,
                                            mandate_id: user.mandate.id}
      }.to change(mandate_messages_query, :count).by(1)
    end

    it "sends messenger message with correct content to clark users" do
      allow(Features).to receive(:active?).with(Features::MESSENGER).and_return(true)
      post :send_rating_message, params: {locale: I18n.locale,
                                          mandate_id: user.mandate.id}

      last_message_to_mandate = Interaction::Message.where(mandate: user.mandate).last

      expect(last_message_to_mandate.content).to be_present
    end

    it "does not send a push notification as a fall back" do
      allow(Features).to receive(:active?).with(Features::MESSENGER).and_return(true)
      post :send_rating_message, params: {locale: I18n.locale,
                                          mandate_id: user.mandate.id}
      expect_any_instance_of(OutboundChannels::PushWithSmsFallback).not_to receive(:send_message)
    end
  end
end
