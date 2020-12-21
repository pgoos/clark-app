# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::OpportunitiesController, :integration, type: :controller do
  let(:role)  { create(:role, permissions: Permission.where(controller: "admin/opportunities")) }
  let(:admin) { create(:admin, role: role) }
  let(:mandate)     { create(:mandate, user: create(:user)) }
  let(:opportunity) { create(:opportunity) }
  let(:category)    { create(:category_phv) }

  let(:aoa_data) do
    {
      available_consultants: [
        {
          id: 1,
          performance_level: "A",
          open_leads: 10,
          open_leads_category_counts: {
            "0334db57": 3,
            "0c6a6cb2": 7
          },
          revenue: 5000.0,
          performance_matrix: {
            "10": {
              "3000": 0.2,
              "9000": 0.4
            },
            "20": {
              "3000": 0.5,
              "9000": 0.4
            }
          }
        },
        {
          id: 2,
          performance_level: "b",
          open_leads: 10,
          open_leads_category_counts: {
            "0334db57": 3,
            "0c6a6cb2": 7
          },
          revenue: 5000.0,
          performance_matrix: {
            "10": {
              "3000": 0.1,
              "9000": 0.2
            },
            "20": {
              "3000": 0.3,
              "9000": 0.4
            }
          }
        }
      ]
    }.to_json
  end

  before { login_admin(admin) }

  context "#assign" do
    context "assigns" do
      let(:payload) { { locale: :de, opportunity: { admin_id: admin.id, aoa_data: aoa_data } } }

      it "when admin and opportunity are present" do
        patch :assign, params: { id: opportunity }.merge(payload)

        opportunity.reload
        expect(opportunity.admin).to eq(admin)
      end

      it "creates a new 'sales_consultant_assigned' business event" do
        patch :assign, params: { id: opportunity }.merge(payload)

        expect(
          BusinessEvent
            .find_by(person: admin, action: "sales_consultant_assigned")
            .metadata["available_consultants"]
            .count
        ).to eq(2)
      end
    end

    context "does not assign" do
      it "when admin is not present" do
        patch :assign, params: {id: opportunity, locale: :de}
        expect(flash[:alert]).to be_present
      end
    end
  end

  context "#automated_household_contents_offer" do
    let!(:opportunity) { create(:opportunity, mandate: mandate) }
    let(:household_rule) { Domain::OfferGeneration::HouseholdContents::HouseholdOfferFromComparison }
    let(:job_class) { OfferAutomationRuleEngineV4Job }
    let(:household_job_id) { rand(100).ceil.to_s }
    let(:household_job) { double("household job", job_id: household_job_id) }

    it "delays the automation" do
      expect(job_class)
        .to receive(:perform_later)
        .with(opportunity_id: opportunity.id, rule_class: household_rule.to_s)
        .and_return(household_job)

      patch :automated_household_contents_offer, params: {id: opportunity.id, locale: :de, format: :json}

      expect(json_response.job).to eq(household_job_id)
    end
  end

  describe "GET #index" do
    let(:category) { create(:bu_category) }
    let!(:opportunity) { create(:opportunity, category: category) }

    it "renders opportunity index page" do
      get :index, params: { locale: I18n.locale }
      expect(response.status).to eq(200)
    end

    context "with revoked mandate" do
      let!(:revoked_opportunity) { create(:opportunity, category: category) }

      it "should render only active mandate appointments" do
        revoked_opportunity.mandate.update!(state: :revoked)
        get :index, params: { locale: I18n.locale }
        expect(assigns(:opportunities)).to match_array([opportunity])
      end

      context "with view_revoked_mandates permission" do
        before do
          admin.permissions << create(:permission, :view_revoked_mandates)
        end

        it "should render only active mandate appointments" do
          revoked_opportunity.mandate.update!(state: :revoked)
          get :index, params: { locale: I18n.locale }
          expect(assigns(:opportunities)).to match_array([opportunity, revoked_opportunity])
        end
      end
    end
  end

  context "#show" do
    let(:category)    { create(:bu_category) }
    let(:opportunity) { create(:opportunity, category: category) }

    it "renders opportunity page" do
      get :show, params: {id: opportunity.id, locale: :de}
      expect(response.status).to eq(200)
    end
  end

  describe "GET /edit" do
    let(:opportunity) { create(:opportunity) }

    before do
      get :edit, params: {id: opportunity.id, locale: :de}
    end

    it { is_expected.to render_template("edit") }

    it { is_expected.to respond_with(200) }
  end

  describe "PUT /update" do
    let(:opportunity) { create(:opportunity) }
    let(:sales_campaign) { create(:sales_campaign) }
    let(:attributes) do
      {
        "admin_id" => admin.id,
        "source_description" => "Adsense",
        "sales_campaign_id" => sales_campaign.id,
        "presales_agent_id" => admin.id
      }
    end

    context "when attributes are passed in" do
      it "update passed in attributes" do
        put :update, params: { id: opportunity.id, opportunity: attributes, locale: :de }
        opportunity_exists = Opportunity.exists?(
          id: opportunity.id,
          admin_id: admin.id,
          sales_campaign_id: sales_campaign.id,
          presales_agent: admin
        )

        expect(opportunity_exists).to be_truthy
        expect(response).to redirect_to(admin_opportunity_path(opportunity))
        expect(flash[:notice]).to eq("Gelegenheit wurde erfolgreich aktualisiert.")
      end
    end

    context "when preferred_insurance_start_date and previous_damages are given" do
      let(:opportunity) { create(:opportunity, mandate: mandate) }
      let(:previous_damages) { "Something happened" }
      let(:preferred_insurance_start_date) { "2020-06-24" }

      it "stores the value in opportunity's metadata" do
        params = {
          locale: I18n.locale,
          mandate_id: mandate.id,
          id: opportunity.id,
          opportunity: {
            previous_damages: previous_damages,
            preferred_insurance_start_date: preferred_insurance_start_date
          }
        }

        patch :update, params: params

        opportunity.reload

        expected = {
          "preferred_insurance_start_date" => preferred_insurance_start_date,
          "previous_damages" => previous_damages
        }

        expect(opportunity.metadata).to include(expected)
      end
    end
  end

  describe "PATCH cancel" do
    let(:category) { create(:bu_category) }
    let(:user) { create(:user) }
    let(:mandate) { create(:mandate, :created, user: user) }
    let(:params) { {id: opportunity.id, locale: :de} }

    let(:opportunity) do
      create(:opportunity,
             category: category,
             admin: admin,
             mandate: mandate,
             state: :initiation_phase)
    end

    before do
      patch :cancel, params: params
    end

    it "redirects to opportunity page" do
      opportunity.reload

      expect(opportunity.state).to eq("lost")
      expect(opportunity.loss_reason).to eq(nil)
      expect(response).to redirect_to(admin_opportunity_path(opportunity))
      expect(flash[:alert]).not_to eq(I18n.t("admin.opportunities.errors.mandate_state"))
    end

    context "with loss reason" do
      let(:params) { {id: opportunity.id, locale: :de, opportunity: {loss_reason: "fake"}} }

      it "saves loss reason in opportunity" do
        opportunity.reload

        expect(opportunity.loss_reason).to eq("fake")
      end
    end
  end

  context "when created with a prospect" do
    let(:first_name) { "Waldi" }
    let(:last_name) { "Waldemar" }
    let(:category) { create(:category) }
    let(:street) { "Funstreet" }
    let(:sales_campaign) { create(:sales_campaign) }
    let(:params) do
      {
        "opportunity[mandate_attributes][first_name]": first_name,
        "opportunity[mandate_attributes][last_name]": last_name,
        "opportunity[mandate_attributes][gender]": "male",
        "opportunity[mandate_attributes][birthdate]": "1.1.1980",
        "opportunity[mandate_attributes][lead_attributes][email]": "ww@clark.de",
        "opportunity[mandate_attributes][phone]": ClarkFaker::PhoneNumber.phone_number,
        "opportunity[source_description]": "Karneval",
        "opportunity[category_id]": category.id,
        "opportunity[admin_id]": admin.id.to_s,
        "opportunity[sales_campaign_id]": sales_campaign.id,
        "opportunity[presales_agent_id]": admin.id,
        "opportunity[mandate_attributes][active_address_attributes][street]": street,
        "opportunity[mandate_attributes][active_address_attributes][house_number]": "99",
        "opportunity[mandate_attributes][active_address_attributes][zipcode]": "13456",
        "opportunity[mandate_attributes][active_address_attributes][city]": "Gorgeouscity",
        "opportunity[mandate_attributes][active_address_attributes][country_code]": "DE",
        locale: :de
      }
    end

    it "should create the lead" do
      post :create_with_prospect, params: params
      mandate = Mandate.find_by(first_name: first_name, last_name: last_name)
      expect(mandate).to be_present
      expect(mandate.user_or_lead).to be_a(Lead)
      expect(mandate.opportunities).not_to be_empty
      expect(mandate.active_address.street).to eq(street)
      expect(mandate.opportunities.take.sales_campaign).to eq(sales_campaign)
      expect(mandate.opportunities.take.presales_agent).to eq(admin)
    end
  end

  describe "#classify" do
    context "admin can change opportunity class" do
      it "classifies correctly" do
        level = Opportunity.levels[:b]
        payload = { locale: :de, opportunity: { level: level } }
        patch :classify, params: { id: opportunity }.merge(payload)

        opportunity.reload
        expect(opportunity.level).to eq(level)
      end
    end
  end

  describe "POST create" do
    let(:sales_campaign) { create(:sales_campaign) }
    let(:presales_agent) { create(:admin) }
    let(:params) do
      {
        source_type: "",
        source_id: "",
        source_description: "",
        sales_campaign_id: sales_campaign.id,
        presales_agent_id: presales_agent.id,
        admin_id: admin.id,
        category_id: category.id,
        old_product_id: "",
        level: "not_set",
        preferred_insurance_start_date: "2020-06-25",
        previous_damages: "Teste"
      }
    end

    context "when valid" do
      it "creates a new opportunity" do
        expect {
          post :create, params: { locale: I18n.locale, mandate_id: mandate.id, opportunity: params }
        }.to change(Opportunity, :count).by(1)
        expect(mandate.opportunities.take.sales_campaign).to eq(sales_campaign)
        expect(mandate.opportunities.take.presales_agent).to eq(presales_agent)
      end
    end
  end
end
