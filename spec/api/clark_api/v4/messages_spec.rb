# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::V4::Messages, :integration do
  let(:user) { create :user, :with_mandate }

  def response_message_ids
    json_response.fetch("messages", []).map { |m| m["id"] }
  end

  describe "GET /messages" do
    let!(:message1) { create :interaction_message, :with_mandate }
    let!(:message2) { create :interaction_message, mandate: user.mandate }

    it "responds with collection of messages" do
      login_as(user, scope: :user)

      json_get_v4 "/api/messages"

      expect(response.status).to eq 200
      expect(response_message_ids).to eq [message2.id]
      expect(json_response["count"]).to eq 1
    end

    context "with pagination params" do
      let!(:message1) { create :interaction_message, mandate: user.mandate }
      let!(:message2) { create :interaction_message, mandate: user.mandate }
      let!(:message3) { create :interaction_message, mandate: user.mandate }
      let!(:message4) { create :interaction_message, mandate: user.mandate }
      let!(:message5) { create :interaction_message, mandate: user.mandate }

      it "responds with paginated collection" do
        login_as(user, scope: :user)

        json_get_v4 "/api/messages", max: 2, before: message5.id, after: message1.id

        expect(response.status).to eq 200
        expect(response_message_ids).to match_array [message4.id, message3.id]
      end
    end

    context "when not logged in" do
      it "responds with an error" do
        json_get_v4 "/api/messages"
        expect(response.status).to eq(401)
      end
    end
  end

  context "POST /messages" do
    let(:admin) { create(:admin) }
    let(:params) { {content: "this is a message from a customer"} }

    context "when logged in as user with mandate" do
      before do
        login_as(user, scope: :user)
      end

      it "stores a message for the users mandate" do
        expect { json_post_v4("/api/messages", params) }.to change { Interaction::Message.count }.by(1)

        expect(response.status).to eq 201
        expect(json_response.id).to eq Interaction::Message.last.id
        expect(Interaction::Message.last.mandate_id).to eq user.mandate_id
        expect(Interaction::Message.last.content).to eq "this is a message from a customer"
        expect(Interaction::Message.last.direction).to eq "in"
      end

      context "with platform param" do
        let(:params) { {content: "BLA", platform: "mobile_app"} }

        it "stores platform in message" do
          expect { json_post_v4("/api/messages", params) }.to change { Interaction::Message.count }.by(1)

          expect(response.status).to eq 201
          expect(json_response.id).to eq Interaction::Message.last.id
          expect(Interaction::Message.last.platform).to eq "mobile_app"
        end

        context "when platform has invalid value" do
          let(:params) { {content: "BLA", platform: "INVALID"} }

          it "responds with validation error" do
            expect { json_post_v4("/api/messages", params) }.not_to change(Interaction::Message, :count)

            expect(response.status).to eq 400
          end
        end
      end

      context "with document" do
        let(:withDocument) {
          @file = fixture_file_upload("#{Rails.root}/spec/fixtures/files/blank.pdf")
          {
            content: "BLA",
            platform: "desktop",
            file: [@file]
          }
        }
        let(:withoutDocument) { {content: "BLA", platform: "desktop"} }

        it "receives document in message" do
          post_v4("/api/messages", withDocument)

          expect(response.status).to eq 201
          expect(json_response.id).to eq Interaction::Message.last.id
          expect(json_response.documents.first.file_name).to eq "blank.pdf"
        end

        it "receives no document in message" do
          json_post_v4("/api/messages", withoutDocument)

          expect(response.status).to eq 201
          expect(json_response.id).to eq Interaction::Message.last.id
          expect(json_response.documents).to eq []
        end
      end

      context "message processing" do
        let(:relay) { OutboundChannels::Messenger::MessageRelay }
        let(:params) { {content: "this is a message from a customer"} }

        it "is successfull" do
          allow(relay).to receive(:confirm_message_via_socket)

          json_post_v4 "/api/messages", params

          expect(response.status).to eq 201
        end

        it "passes message to be acknowledge via socket" do
          expect(relay).to receive(:confirm_message_via_socket)
          json_post_v4 "/api/messages", params
        end
      end

      it "marks all outgoing messages as read when a mandate responds with a message" do
        unread_message = Interaction::Message.create!(
          content: "BLA BLA",
          mandate: user.mandate,
          admin: admin,
          direction: Interaction.directions[:out],
          acknowledged: false
        )

        json_post_v4 "/api/messages", params

        expect(unread_message.reload.acknowledged).to eq true
      end
    end

    context "when logged in as lead with mandate" do
      let(:lead) { create :lead }

      before { login_as(lead, scope: :lead) }

      it "stores a message for the users mandate" do
        expect { json_post_v4("/api/messages", params) }.to change(Interaction::Message, :count).by(1)

        expect(response.status).to eq 201
        expect(json_response.id).to eq Interaction::Message.last.id
        expect(Interaction::Message.last.mandate_id).to eq lead.mandate_id
      end
    end

    context "when not logged in" do
      it "does not store a message" do
        expect { json_post_v4("/api/messages", params) }.not_to change(Interaction::Message, :count)

        expect(response.status).to eq 401
      end
    end
  end
end
