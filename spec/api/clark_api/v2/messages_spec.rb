# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::V2::Messages, :integration do
  let(:user) { create(:user, mandate: create(:mandate)) }
  let(:lead) { create(:lead, mandate: create(:mandate)) }
  let(:prospect_customer) { create(:customer, :prospect) }
  let(:self_service_customer) { create(:customer, :self_service) }
  let(:admin) { create(:admin) }
  let(:content) { Faker::Lorem.characters(number: 50) }

  before do
    allow(Features).to receive(:active?).and_return(false)
    allow(Features).to receive(:active?).with(Features::MESSENGER).and_return(true)
  end

  shared_examples "returns unauthorized" do
    it do
      subject
      expect(response.status).to eq(401)
    end
  end

  context "POST api/messages" do
    subject { json_post_v2 "/api/messages", params }

    let(:params) { {content: "this is a message from a customer"} }

    context "when logged in as user with mandate" do
      before { login_as(user, scope: :user) }

      it "stores a message for the users mandate" do
        expect { subject }.to change { Interaction::Message.count }.by(1)

        expect(response.status).to eq(201)
        expect(json_response.id).to eq(Interaction::Message.last.id)
        expect(Interaction::Message.last.mandate_id).to eq(user.mandate_id)
        expect(Interaction::Message.last.content).to eq("this is a message from a customer")
        expect(Interaction::Message.last.direction).to eq("in")
      end

      context "message processing" do
        subject { json_post_v2 "/api/messages", params }

        let(:params) do
          {
            content:         "this is a message from a customer",
            context_id:      1,
            context_type:    "Product"
          }
        end

        let(:relay) { OutboundChannels::Messenger::MessageRelay }
        let(:processor) { Domain::Messenger::InteractionProcessor }

        it "is successfull" do
          allow(relay).to receive(:confirm_message_via_socket)
          allow(processor).to receive(:process_message)
          subject
          expect(response.status).to eq(201)
        end

        it "passes message and params to a processor" do
          expect(relay).to receive(:confirm_message_via_socket)
          subject
        end

        it "passes message to be acknowledge via socket" do
          expect(processor).to receive(:process_message)
          subject
        end
      end

      it "marks all outgoing messages as read when a mandate responds with a message" do
        unread_message = Interaction::Message.create!(
          content: content,
          mandate: user.mandate,
          admin: admin,
          direction: Interaction.directions[:out],
          acknowledged: false
        )
        subject
        expect(unread_message.reload.acknowledged).to eq(true)
      end

      context "when text is missing" do
        before { params.delete(:content) }

        it "does not store a message and returns validation error" do
          expect { subject }.not_to change { Interaction::Message.count }

          expect(response.status).to eq(400)
          expect(json_response.errors.api.content).to include("muss ausgefüllt werden")
        end
      end
    end

    context "when logged in as lead with mandate" do
      before { login_as(lead, scope: :lead) }

      it "stores a message for the users mandate" do
        expect { subject }.to change { Interaction::Message.count }.by(1)

        expect(response.status).to eq(201)
        expect(json_response.id).to eq(Interaction::Message.last.id)
        expect(Interaction::Message.last.mandate_id).to eq(lead.mandate_id)
      end
    end

    shared_examples "does not store a message" do
      it do
        expect { subject }.not_to change { Interaction::Message.count }
        expect(response.status).to eq(401)
      end
    end

    context "when logged in as prospect customer" do
      before { login_customer(prospect_customer, scope: :lead) }

      include_examples "does not store a message"
    end

    context "when logged in as self_service customer" do
      before { login_customer(self_service_customer, scope: :user) }

      include_examples "does not store a message"
    end

    context "when not logged in" do
      include_examples "does not store a message"
    end
  end

  context "GET /api/messages" do
    subject { json_get_v2 "/api/messages", params }

    let(:params) do
      {
        limit: "2",
        younger_than: younger_than,
        older_than: older_than
      }
    end
    let(:younger_than) { 30.minutes.ago.to_time.to_i.to_s }
    let(:older_than) { 5.minutes.ago.to_time.to_i.to_s }

    context "when logged in as user with mandate" do
      before do
        login_as(user, scope: :user)
        create(:interaction_message, mandate: user.mandate, created_at: 20.minutes.ago, content: "message 1",
                                     direction: Interaction.directions[:in])
        create(:interaction_message, mandate: user.mandate, created_at: 25.minutes.ago, content: "message 2",
                                     direction: Interaction.directions[:out])
        create(:interaction_message, mandate: user.mandate, created_at: 40.minutes.ago, content: "message 3",
                                     direction: Interaction.directions[:in])
      end

      it "returns one of the messages" do
        subject

        expect(response.status).to eq(200)
        expect(json_response.messages.size).to eq(2)
        expect(json_response["count"]).to eq(3)
        expect(json_response.messages.first.content).to eq("message 2")
        expect(json_response.messages.first.direction).to eq("out")
        expect(json_response.messages.last.content).to eq("message 1")
        expect(json_response.messages.last.direction).to eq("in")
        expect(json_response.next).to start_with("http://www.example.com/api/messages?limit=2&younger_than=")
        expect(json_response.previous).to start_with("http://www.example.com/api/messages?limit=2&older_than=")
      end
    end

    context "when logged in as prospect customer" do
      before { login_customer(prospect_customer, scope: :lead) }

      include_examples "returns unauthorized"
    end

    context "when logged in as self_service_customer with mandate" do
      it "respond with 200" do
        login_customer(self_service_customer, scope: :user)
        subject

        expect(response.status).to eq(200)
      end
    end

    context "when not logged in" do
      include_examples "returns unauthorized"
    end
  end

  context "POST /api/messages/token" do
    subject { json_post_v2 "/api/messages/token" }

    context "when logged in as user with mandate" do
      before { login_as(user, scope: :user) }

      it "returns a JWT" do
        subject

        expect(response.status).to eq(200)
        expect(json_response.token).to be_kind_of(String)
      end
    end

    context "when logged in as lead with mandate" do
      before { login_as(lead, scope: :lead) }

      it "returns a JWT" do
        subject

        expect(response.status).to eq(200)
        expect(json_response.token).to be_kind_of(String)
      end
    end

    context "when logged in as prospect customer" do
      before { login_customer(prospect_customer, scope: :lead) }

      include_examples "returns unauthorized"
    end

    context "when logged in as self_service customer" do
      before { login_customer(self_service_customer, scope: :user) }

      it "returns a JWT" do
        subject

        expect(response.status).to eq(200)
        expect(json_response.token).to be_kind_of(String)
      end
    end

    context "when not logged in" do
      include_examples "returns unauthorized"
    end
  end

  context "PATCH /api/messages/mark_all_read" do
    subject { json_patch_v2 "/api/messages/mark_all_read" }

    before do
      allow(Comfy::Cms::Site).to receive_message_chain(:find_by, :hostname).and_return("http://test-host-clark.de")
    end

    context "logged in as mandate user" do
      before { login_as(user, scope: :user) }

      it "marks all outgoing messages as read" do
        unread_message = Interaction::Message.create!(
          content:      content,
          mandate:      user.mandate,
          admin:        admin,
          direction:    Interaction.directions[:out],
          acknowledged: false
        )
        subject
        expect(response.status).to eq(200)

        expect(unread_message.reload.acknowledged).to eq(true)
      end
    end

    context "when logged in as prospect customer" do
      before { login_customer(prospect_customer, scope: :lead) }

      include_examples "returns unauthorized"
    end

    context "when logged in as self_service customer" do
      let!(:unread_message) do
        Interaction::Message.create!(
          content: content,
          mandate_id: self_service_customer.id,
          admin: admin,
          direction: Interaction.directions[:out],
          acknowledged: false
        )
      end

      before { login_customer(self_service_customer, scope: :user) }

      it "marks all outgoing messages as read" do
        subject
        expect(response.status).to eq(200)
        expect(unread_message.reload.acknowledged).to eq(true)
      end
    end

    context "when not logged in" do
      include_examples "returns unauthorized"
    end
  end
end
