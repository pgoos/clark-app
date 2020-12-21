# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Opportunities::AppointmentsController, :integration, type: :request do
  let(:role) do
    create(:role, permissions: Permission.where(controller: "admin/sales_campaigns"))
  end
  let(:admin) { create(:admin, role: role) }

  before { sign_in(admin) }

  describe "GET /" do
    let(:campaign_name) { "retarget_2020_04" }
    let!(:sales_campaign) { create(:sales_campaign, name: campaign_name) }
    context "when sales_campaigns exist" do

      it "shows sales_campaigns" do
        get admin_sales_campaigns_path(locale: :de)

        expect(response).to be_successful
        expect(response.body).to include("Sales Kampagnen")
        expect(response.body).to include(campaign_name)
        expect(response.body).to include(sales_campaign.description)
      end
    end

    context "when search_term is passed" do
      let!(:campaign) { create(:sales_campaign, name: "adsense_2020") }

      it "shows only matched result" do
        get admin_sales_campaigns_path(locale: :de, search_term: "retarget")

        expect(response.body).to include("retarget_2020_04")
        expect(response.body).not_to include("adsense_2020")
      end
    end
  end

  describe "GET /new" do
    context "when new page is visited" do
      it "shows campaign creation page" do
        get admin_sales_campaigns_path(locale: :de)

        expect(response).to be_successful
        expect(response.body).to include("Neue Sales Kampagne anlegen")
      end
    end
  end

  describe "POST /" do
    let(:request_params) do
      {
        "sales_campaign" => {
          "name" => "T-1000",
          "description" => "D-Day"
        }
      }
    end

    context "when new campaign name is requested" do
      it "creates new Sales Campaign" do
        post admin_sales_campaigns_path(
          sales_campaign: request_params["sales_campaign"],
          locale: :de
        )

        expect(response).to redirect_to(admin_sales_campaigns_path)
        expect(SalesCampaign.count).to eq(1)
        expect(request.flash[:notice]).to eq("Sales Kampagne wurde erfolgreich erstellt.")
      end
    end

    context "when campaign name already exists" do
      it "shows error message" do
        create(:sales_campaign, name: "T-1000")
        post admin_sales_campaigns_path(
          sales_campaign: request_params["sales_campaign"],
          locale: :de
        )

        expect(response).to redirect_to(admin_sales_campaigns_path)
        expect(SalesCampaign.count).to eq(1)
        expect(request.flash[:notice]).to eq(
          "Eine Kampagne mit dem Namen T-1000 existiert bereits."
        )
      end

      context "when same name in upcase is requested" do
        let!(:sales_campaign) { create(:sales_campaign, name: "t-1000") }

        it "shows error message" do
          post admin_sales_campaigns_path(
            sales_campaign: request_params["sales_campaign"],
            locale: :de
          )

          expect(response).to redirect_to(admin_sales_campaigns_path)
          expect(SalesCampaign.count).to eq(1)
          expect(request.flash[:notice]).to eq(
            "Eine Kampagne mit dem Namen T-1000 existiert bereits."
          )
        end
      end
    end
  end

  describe "PUT /toggle_status" do
    context "when sales_campaigns exist" do
      let(:sales_campaign) { create(:sales_campaign, active: false) }

      it "toggle sales_campaign#active flag" do
        put toggle_status_admin_sales_campaign_path(sales_campaign, locale: :de)

        expect(response).to redirect_to(admin_sales_campaigns_path)
        expect(sales_campaign.reload.active).to be_truthy
        expect(request.flash[:notice]).to eq(
          "Sales Kampagne wurde erfolgreich aktiviert/deaktiviert."
        )
      end
    end
  end
end
