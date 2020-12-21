# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::MandateMilesAndMoreController, :integration, type: :controller do
  let(:role) { create(:role, permissions: Permission.where(controller: "admin/mandate_miles_and_more")) }
  let(:admin) { create(:admin, role: role) }
  let(:mandate) { create :mandate, user: user }
  let(:user) { create :user, source_data: source_data }

  let(:source_data) do
    {adjust: {network: "mam"}}
  end

  before { login_admin(admin) }

  describe "PATCH /update" do
    context "when a correct card number is entered" do
      before do
        response_wrapper = Domain::Partners::MilesMore::ResponseWrapper.new(nil)
        allow_any_instance_of(Domain::Partners::MilesMore)
          .to receive(:update_card_number!).and_return(response_wrapper)
      end

      it "redirects to the current route and flashes success notice" do
        patch :update, params: {id: mandate.id, locale: :de, mandate: {mam_member_alias: "12345z"}}
        expect(flash[:notice]).to eq "success"
      end
    end

    context "when an incorrect card number is entered" do
      before do
        response_wrapper = Domain::Partners::MilesMore::ResponseWrapper.new(
          data: {message: "this failed"}
        )
        allow_any_instance_of(Domain::Partners::MilesMore)
          .to receive(:update_card_number!).and_return(response_wrapper)
      end

      it "redirects to the current route and flashes success notice" do
        patch :update, params: {id: mandate.id, locale: :de, mandate: {mam_member_alias: "12345z"}}
        expect(flash[:alert]).to eq "this failed"
      end
    end
  end
end
