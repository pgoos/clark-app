# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::RegistrationsController, :integration, type: :controller do
  # Settings
  before do
    request.env["devise.mapping"]      = Devise.mappings[:user]
    request.env["latest_landing_page"] = "milesandmore"
  end

  # Concerns
  # Filter
  # Actions
  describe "user registration" do
    subject { post(:create, params: params) }

    let(:params) { { user: user_params, locale: "de" } }
    let(:user_params) {
      {
        email: Faker::Internet.email,
        password: Settings.seeds.default_password,
        password_confirmation: Settings.seeds.default_password
      }
    }

    context "when user registers with mam source" do
      let(:mam_landing_page) {
        "http://localhost:3000/de/?utm_source=mam&utm_campaign=Feb17&utm_medium=BrandPage&utm_content=content"
      }
      let(:mam_special_landing_page) { "http://localhost:3000/de/milesandmore" }
      let(:mam_utm_source) { "mam" }
      let(:mam_utm_campaign) { "Feb17" }
      let(:mam_utm_campaign_special) { "Feb01" }
      let(:mam_utm_medium) { "BrandPage" }
      let(:mam_utm_medium_special) { "something" }
      let(:mam_utm_term) { "banner" }
      let(:mam_utm_content) { "content" }

      let(:current_visit_normal) do
        {
          "landing_page" => mam_landing_page,
          "utm_source" => mam_utm_source,
          "utm_campaign" => mam_utm_campaign,
          "utm_medium" => mam_utm_medium,
          "utm_term" => mam_utm_term,
          "utm_content" => mam_utm_content
        }
      end
      let(:current_visit_empty) do
        {
          "utm_source" => "",
          "utm_campaign" => "",
          "utm_medium" => "",
          "utm_term" => ""
        }
      end
      let(:current_visit_special) do
        {
          "landing_page" => mam_special_landing_page
        }
      end
      let(:current_visit_miles_more_referrer) do
        {
          "referrer" => "milesandmore.com"
        }
      end

      it "adds the adjust data to the user having the mam specific params" do
        allow_any_instance_of(described_class).to receive(:current_visit).and_return(current_visit_normal)
        subject
        adjust = User.last.source_data["adjust"]
        expect(adjust["network"]).to eq(mam_utm_source)
        expect(adjust["campaign"]).to eq(mam_utm_campaign)
        expect(adjust["creative"]).to eq(mam_utm_term)
        expect(adjust["adgroup"]).to eq(mam_utm_content)
      end

      it "does not overwrite adjust data if the params are empty" do
        installation_id = Faker::Internet.device_token
        params[:installation_id] = installation_id
        source_data = {
          "adjust" => {
            "network" => mam_utm_source,
            "campaign" => mam_utm_campaign,
            "creative" => mam_utm_medium,
            "adgroup" => mam_utm_term
          }
        }
        create(:device_lead, :with_mandate, installation_id: installation_id, source_data: source_data)
        allow_any_instance_of(described_class).to receive(:current_visit).and_return(current_visit_empty)
        expect(DeviceLeadConverter).to receive(:convert_device_lead_to_user).and_call_original

        subject

        adjust = User.last.adjust
        expect(adjust["network"]).to eq(mam_utm_source)
        expect(adjust["campaign"]).to eq(mam_utm_campaign)
        expect(adjust["creative"]).to eq(mam_utm_medium)
        expect(adjust["adgroup"]).to eq(mam_utm_term)
      end

      it "adds the adjust data to the lead having the mam specific params (no user available)" do
        allow_any_instance_of(described_class).to receive(:current_user).and_return(nil)
        allow_any_instance_of(described_class).to receive(:current_visit).and_return(current_visit_special)
        lead = create(:lead)
        allow_any_instance_of(described_class).to receive(:current_lead).and_return(lead)
        subject
        expect(Lead.last.mandate.mam_enabled?)
      end

      it "adds the adjust data to the user coming from a special url" do
        allow_any_instance_of(described_class).to receive(:current_visit).and_return(current_visit_special)
        request.session[:latest_landing_page] = "milesandmore"
        subject
        adjust = User.last.source_data["adjust"]
        expect(adjust["network"]).to eq(mam_utm_source)
        expect(adjust["campaign"]).to be_nil
        expect(adjust["creative"]).to be_nil
      end

      it "adds mam specific data to a user with a visit referring to miles-and-more" do
        allow_any_instance_of(described_class).to receive(:current_visit).and_return(current_visit_miles_more_referrer)
        subject
        adjust = User.last.source_data["adjust"]
        expect(adjust["network"]).to eq(mam_utm_source)
        expect(adjust["campaign"]).to be_nil
        expect(adjust["creative"]).to be_nil
      end

      it "identifies current_visit_normal as miles and more" do
        allow_any_instance_of(Users::RegistrationsController)
          .to receive(:get_landing_from_session).and_return("milesandmore")
        allow_any_instance_of(described_class).to receive(:current_visit).and_return(current_visit_normal)
        result = described_class.new.send("miles_and_more?")
        expect(result).to be_truthy
      end

      it "identifies current_visit_special as miles and more" do
        allow_any_instance_of(Users::RegistrationsController)
          .to receive(:get_landing_from_session).and_return("milesandmore")
        allow_any_instance_of(described_class).to receive(:current_visit).and_return(current_visit_special)
        result = described_class.new.send("miles_and_more?")
        expect(result).to be_truthy
      end

      it "identifies current_visit_miles_more_referrer as miles and more" do
        allow_any_instance_of(Users::RegistrationsController)
          .to receive(:get_landing_from_session).and_return("milesandmore")
        allow_any_instance_of(described_class).to receive(:current_visit).and_return(current_visit_miles_more_referrer)
        result = described_class.new.send("miles_and_more?")
        expect(result).to be_truthy
      end

      it "does not identify empty current_visit as miles and more" do
        allow_any_instance_of(described_class).to receive(:current_visit).and_return({})
        result = described_class.new.send("miles_and_more?")
        expect(result).to be_falsey
      end
    end

    context "when user registers with payback source" do
      let(:payback_hex_value) { "7061796261636b" }
      let(:visit_with_utm_source) {
        {
          "utm_source" => "payback"
        }
      }
      let(:visit_from_landing_page) {
        {
          "landing_page" => "http://localhost:3000/de/cms/payback"
        }
      }

      it "redirects customer to specific payback mandate funnel from the flow query parameter" do
        allow_any_instance_of(described_class).to receive(:current_user).and_return(nil)
        lead = create(:lead)
        allow_any_instance_of(described_class).to receive(:current_lead).and_return(lead)
        params[:flow] = payback_hex_value
        get :new, params: params
        expect(response).to redirect_to(/\/app\/mandate\/payback/)
        adjust = Lead.last.source_data["adjust"]
        expect(adjust["network"]).to eq("payback")
      end

      it "redirects customer to specific payback mandate funnel from the utm_source of ahoy visit" do
        allow_any_instance_of(described_class).to receive(:current_user).and_return(nil)
        allow_any_instance_of(described_class).to receive(:current_visit).and_return(visit_with_utm_source)
        lead = create(:lead)
        allow_any_instance_of(described_class).to receive(:current_lead).and_return(lead)

        get :new, params: params
        expect(response).to redirect_to(/\/app\/mandate\/payback/)
        adjust = Lead.last.source_data["adjust"]
        expect(adjust["network"]).to eq("payback")
      end

      it "redirects customer to specific payback mandate funnel from the landing_page source of ahoy visit" do
        allow_any_instance_of(described_class).to receive(:current_user).and_return(nil)
        allow_any_instance_of(described_class).to receive(:current_visit).and_return(visit_from_landing_page)
        lead = create(:lead)
        allow_any_instance_of(described_class).to receive(:current_lead).and_return(lead)

        get :new, params: params
        expect(response).to redirect_to(/\/app\/mandate\/payback/)
        adjust = Lead.last.source_data["adjust"]
        expect(adjust["network"]).to eq("payback")
      end
    end

    context "when customer is coming from home24 landing page" do
      include_context "home24 with order"

      let(:order_number) { home24_order_number }
      let(:home24_hex_value) { "686f6d653234" }
      let(:visit_with_utm_source) {
        {
          "utm_source" => "home24",
          "utm_term" => order_number
        }
      }
      let(:visit_from_landing_page) {
        {
          "landing_page" => "http://localhost:3000/de/cms/home24"
        }
      }

      it "marks source as home24 based on the flow parameter" do
        allow_any_instance_of(described_class).to receive(:current_user).and_return(nil)
        lead = create(:lead)
        allow_any_instance_of(described_class).to receive(:current_lead).and_return(lead)

        params[:flow] = home24_hex_value
        params[:utm_term] = order_number
        get :new, params: params
        lead = Lead.last
        adjust = lead.source_data["adjust"]
        expect(adjust["network"]).to eq("home24")
        expect(lead.mandate.loyalty["home24"]["order_number"]).to eq(order_number)
      end

      it "marks source as home24 based on the utm_source of ahoy visit" do
        allow_any_instance_of(described_class).to receive(:current_user).and_return(nil)
        allow_any_instance_of(described_class).to receive(:current_visit).and_return(visit_with_utm_source)
        lead = create(:lead)
        allow_any_instance_of(described_class).to receive(:current_lead).and_return(lead)

        get :new, params: params
        lead = Lead.last
        adjust = lead.source_data["adjust"]
        expect(adjust["network"]).to eq("home24")
        expect(lead.mandate.loyalty["home24"]["order_number"]).to eq(order_number)
      end

      it "marks source as home24 based on the landing_page source of ahoy visit" do
        allow_any_instance_of(described_class).to receive(:current_user).and_return(nil)
        allow_any_instance_of(described_class).to receive(:current_visit).and_return(visit_from_landing_page)
        lead = create(:lead)
        allow_any_instance_of(described_class).to receive(:current_lead).and_return(lead)

        get :new, params: params
        lead = Lead.last
        adjust = lead.source_data["adjust"]
        expect(adjust["network"]).to eq("home24")
      end
    end

    context "when user registers with bunq source" do
      let(:lead) { create(:lead) }
      let(:visit_from_landing_page) do
        { "landing_page" => "http://localhost:3000/de/cms/bunq" }
      end

      it "adds bunq network if user comes from bunq landing page" do
        allow_any_instance_of(described_class).to receive(:current_user).and_return(nil)
        allow_any_instance_of(described_class).to receive(:current_visit).and_return(visit_from_landing_page)
        allow_any_instance_of(described_class).to receive(:current_lead).and_return(lead)

        get :new, params: params
        expect(response).to redirect_to(/\/app\/mandate\/status/)
        adjust = Lead.last.source_data["adjust"]
        expect(adjust["network"]).to eq("bunq")
      end
    end

    context "when user registers after visiting multiple pages" do
      let(:mam_landing_page) {
        "http://localhost:3000/de/?utm_source=mam&utm_campaign=Feb17&utm_medium=BrandPage&utm_term=banner&utm_content=content"
      }
      let(:mam_special_landing_page) { "http://localhost:3000/de/milesandmore" }
      let(:mam_utm_source) { "mam" }
      let(:mam_utm_campaign) { "Feb17" }
      let(:mam_utm_campaign_special) { "Feb01" }
      let(:mam_utm_medium) { "BrandPage" }
      let(:mam_utm_medium_special) { "something" }
      let(:mam_utm_term) { "banner" }
      let(:mam_utm_content) { "content" }

      let(:current_visit_normal) do
        {
          "landing_page" => mam_landing_page,
          "utm_source" => mam_utm_source,
          "utm_campaign" => mam_utm_campaign,
          "utm_medium" => mam_utm_medium,
          "utm_term" => mam_utm_term,
          "utm_content" => mam_utm_content
        }
      end
      let(:current_visit_special) do
        {
          "landing_page" => mam_special_landing_page
        }
      end
      let(:current_visit_miles_more_referrer) do
        {
          "referrer" => "milesandmore.com"
        }
      end

      it "adds correct source data after landing page is not different from initial page" do
        allow_any_instance_of(described_class).to receive(:current_visit).and_return(current_visit_normal)
        allow_any_instance_of(Users::RegistrationsController)
          .to receive(:get_landing_from_session).and_return("milesandmore")
        subject
        adjust = User.last.adjust
        expect(adjust["network"]).to eq(mam_utm_source)
        expect(adjust["campaign"]).to eq(mam_utm_campaign)
        expect(adjust["creative"]).to eq(mam_utm_term)
        expect(adjust["adgroup"]).to eq(mam_utm_content)
      end

      it "overrides previous adjust data if new landing page is different from initial" do
        allow_any_instance_of(described_class).to receive(:current_visit).and_return(current_visit_normal)
        request.session[:latest_landing_page] = "ing-diba"
        subject
        adjust = User.last.source_data["adjust"]
        expect(adjust["network"]).to eq("ing-diba")
        expect(adjust["campaign"]).to be_nil
        expect(adjust["creative"]).to be_nil
        expect(adjust["adgroup"]).to be_nil
      end

      it "adds correct source data if landing apge is not present based on utm params" do
        allow_any_instance_of(described_class).to receive(:current_visit).and_return(current_visit_normal)
        allow_any_instance_of(Users::RegistrationsController).to receive(:get_landing_from_session).and_return("")
        subject
        adjust = User.last.source_data["adjust"]
        expect(adjust["network"]).to eq("mam")
        expect(adjust["campaign"]).to eq(mam_utm_campaign)
        expect(adjust["creative"]).to eq(mam_utm_term)
        expect(adjust["adgroup"]).to eq(mam_utm_content)
      end

      it "retains landing page info even if goes to a landing page and then visits a link with utm source" do
        request.session[:latest_landing_page] = "ing-diba"
        allow_any_instance_of(described_class).to receive(:current_visit).and_return(current_visit_normal)
        subject
        adjust = User.last.source_data["adjust"]
        expect(adjust["network"]).to eq("ing-diba")
        expect(adjust["campaign"]).to be_nil
        expect(adjust["creative"]).to be_nil
      end

      it "also overides medium and network if its present in the new landing page" do
        request.session[:latest_landing_page] = "ing-diba"
        session[:latest_utm_campaign] = "new_campaign"
        session[:latest_utm_medium] = "new_medium"
        allow_any_instance_of(described_class).to receive(:current_visit).and_return(current_visit_normal)
        subject
        adjust = User.last.source_data["adjust"]
        expect(adjust["network"]).to eq("ing-diba")
        expect(adjust["campaign"]).to eq("new_campaign")
        expect(adjust["medium"]).to eq("new_medium")
      end

      describe "overrides data for a second landing page visit" do
        before do
          session[:latest_utm_campaign] = "new_campaign"
          session[:latest_utm_medium] = "new_medium"
          session[:latest_landing_page] = "ing-diba"
          session[:latest_utm_content] = "new_content"
          session[:latest_utm_term] = "new_term"
        end

        it "overrides the network, campaign and the medium to a new value from session" do
          allow_any_instance_of(described_class).to receive(:current_visit).and_return(current_visit_normal)
          subject
          adjust = User.last.source_data["adjust"]
          expect(adjust["network"]).to eq("ing-diba")
          expect(adjust["campaign"]).to eq("new_campaign")
          expect(adjust["medium"]).to eq("new_medium")
          expect(adjust["medium"]).to eq("new_medium")
          expect(adjust["adgroup"]).to eq("new_content")
          expect(adjust["creative"]).to eq("new_term")
        end
      end
    end

    context "when user registers from a marketing campaign" do
      let(:campaign_landing_page_with_pc_id) {
        "http://localhost:3000/de/?utm_source=disney&utm_campaign=Feb17&utm_medium=BrandPage&pc_id=123&utm_term=banner&utm_content=content"
      }
      let(:campaign_landing_page_without_pc_id) {
        "http://localhost:3000/de/?utm_source=disney&utm_campaign=Feb17&utm_medium=BrandPage&utm_term=banner&utm_content=content"
      }

      let(:current_visit_with_pc_id) do
        {
          "landing_page" => campaign_landing_page_with_pc_id
        }
      end

      let(:current_visit_without_pc_id) do
        {
          "landing_page" => campaign_landing_page_without_pc_id
        }
      end

      it "creates a user with pc_id if present" do
        allow_any_instance_of(described_class).to receive(:current_visit).and_return(current_visit_with_pc_id)
        subject
        expect(User.last.source_data["partner_customer_id"]).to eq("123")
      end

      it "creates a user with pc_id of nil if its not present" do
        allow_any_instance_of(described_class).to receive(:current_visit).and_return(current_visit_without_pc_id)
        subject
        expect(User.last.source_data["partner_customer_id"]).to be_nil
      end
    end

    context "when user registers but there is no lead" do
      it "creates a user without a mandate, since we ensure a lead to be present up front" do
        expect(DeviceLeadConverter).to receive(:convert_device_lead_to_user).and_call_original

        expect { subject }.to change(User, :count).by(1)

        expect(User.last.mandate).not_to be_nil
      end
    end

    context "when installation_id of existing lead is in params" do
      let(:lead) { create :lead, installation_id: installation_id, mandate: mandate }
      let(:installation_id) { Faker::Internet.device_token }
      let(:mandate) { create :mandate }

      before do
        lead
        mandate
        params.merge!(installation_id: installation_id)
      end

      it "creates a user with the mandate of the lead and deletes the lead" do
        expect(DeviceLeadConverter).to receive(:convert_device_lead_to_user).and_call_original

        expect { subject }
          .to change(Lead, :count)
          .by(-1)
          .and change { mandate.reload.lead }
          .from(lead).to(nil)
          .and change { mandate.reload.user }.from(nil)
      end
    end

    context "when existing lead is in session" do
      let(:lead) { create :lead, mandate: mandate }
      let(:mandate) { create :mandate }

      before do
        lead
        mandate # create in DB
        request.env["warden"].set_user(lead, scope: :lead)
      end

      it "creates a user with the mandate of the lead and deletes the lead" do
        expect(DeviceLeadConverter).to receive(:convert_device_lead_to_user).and_call_original

        expect { subject }
          .to change(Lead, :count).by(-1)
                                  .and change { mandate.reload.lead }.from(lead).to(nil)
                                                                     .and change { mandate.reload.user }.from(nil)
      end

      it "migrates the existing adjust data to the user" do
        expected_network = "partner_token"
        lead.update!(source_data: { "adjust" => { "network" => expected_network } })
        lead.reload
        expect(lead.adjust["network"]).to eq(expected_network)

        subject

        expect(mandate.reload.user.adjust["network"]).to eq(expected_network)
      end
    end

    context "update_user_partner_data" do
      let(:visit) { OpenStruct.new }

      context "when updating users source data and inviter code" do
        before do
          allow_any_instance_of(described_class)
            .to receive(:current_visit)
            .and_return(visit)
          params["referrer"] = "finanzblick"
        end

        it "updates user inviter_code to finanzblick if query params present" do
          visit["landing_page"] = "www.google.com/de?referrer=finanzblick&utm_source=Finanzblick"
          subject
          user = User.last
          expect(user.inviter_code).to eq "Finanzblick"
        end

        it "updates user inviter_code to nil if no query params present" do
          visit["landing_page"] = "www.google.com/de?referrer=finanzblick"
          subject
          user = User.last
          expect(user.inviter_code).to be_nil
        end

        it "updates source data of the user if query params present" do
          visit["landing_page"] = "www.google.com/de?referrer=finanzblick&utm_source=Finanzblick&fblick_id=123"
          subject
          user = User.last
          expect(user.source_data["fblick_id"]).to eq "123"
          expect(user.source_data["referrer"]).to eq "Finanzblick"
        end

        it "updates source data of the user to nil if no relevant query params present" do
          visit["landing_page"] = "www.google.com/de?referrer=finanzblick"
          subject
          user = User.last
          expect(user.source_data["fblick_id"]).to be_nil
          expect(user.source_data["referrer"]).to be_nil
        end
      end
    end

    context "when a user registers with assona as source" do
      let(:partner) { "assona" }
      let(:product_id) { "12345" }

      it "adds the product id to user source data if exists" do
        session[:product_id] = product_id
        session[:partner] = partner
        get :new, params: { locale: "de" }
        subject
        partner_products = User.last.source_data["partner_products"]
        expect(partner_products.first["partner"]).to eq(partner)
        expect(partner_products.first["id"]).to eq(product_id)
      end

      it "does not add the product id to user source data if url is not matching" do
        subject
        partner_products = User.last.source_data["partner_products"]
        expect(partner_products).to eq(nil)
      end
    end

    context "when a user comes from the refer a friend link" do
      let(:current_referral_code_with_value) { "2132" }

      it "set the source data to referral program" do
        allow_any_instance_of(described_class)
          .to receive(:current_referral_code).and_return(current_referral_code_with_value)
        subject
        adjust = User.last.source_data["adjust"]
        expect(adjust["network"]).to eq("referral program")
      end

      it "should update the invited code fo the current lead" do
        allow_any_instance_of(described_class)
          .to receive(:current_referral_code).and_return(current_referral_code_with_value)
        subject
        code = User.last.inviter_code
        expect(code).to eq(current_referral_code_with_value)
      end

      it "should set the campaign to nil" do
        allow_any_instance_of(described_class)
          .to receive(:current_referral_code).and_return(current_referral_code_with_value)
        subject
        adjust = User.last.source_data["adjust"]
        expect(adjust["campaign"]).to be_nil
      end
    end

    context "when updating the owner ident" do
      let(:current_visit_normal) do
        {
          "landing_page" => "http://localhost:3000/de/somelandingpage",
          "utm_source" => "some source",
          "utm_campaign" => "some campaign",
          "utm_medium" => "some medium",
          "utm_term" => "some utm source"
        }
      end

      it "doesnt update owner if network is not malburg" do
        allow_any_instance_of(described_class).to receive(:current_visit).and_return(current_visit_normal)
        get :new, params: { locale: "de" }
        subject
        expect(User.last.source_data["adjust"]["network"]).to eq(current_visit_normal["utm_source"])
        expect(User.last.mandate.owner_ident).to eq("clark")
      end

      it "updates owner when network is malburg" do
        current_visit_normal["utm_source"] = "malburg"
        allow_any_instance_of(described_class).to receive(:current_visit).and_return(current_visit_normal)
        get :new, params: { locale: "de" }
        subject
        expect(User.last.source_data["adjust"]["network"]).to eq(current_visit_normal["utm_source"])
        expect(User.last.mandate.owner_ident).to eq(current_visit_normal["utm_source"])
      end
    end

    context "when updating mandate sovendus data" do
      let(:token) { "some_token" }
      let(:current_visit_normal) do
        {
          "landing_page" => "http://localhost:3000/de/somelandingpage",
          "utm_source" => network,
          "utm_content" => token
        }
      end

      before { allow_any_instance_of(described_class).to receive(:current_visit).and_return(current_visit_normal) }

      context "when user registers from sovendus" do
        let(:network) { OutboundChannels::Sovendus::SOVENDUS_MANDATE_SOURCE }

        it "sets sovendus token in mandate info" do
          get :new, params: { locale: "de" }
          subject
          expect(User.last.mandate.info["sovendus_request_token"]).to eq(token)
        end
      end

      context "when user registers from anywhere else" do
        let(:network) { "some_network" }

        it "does NOT set sovendus token in mandate info" do
          get :new, params: { locale: "de" }
          subject
          expect(User.last.mandate.info["sovendus_request_token"]).to be_nil
        end
      end
    end

    describe "cash_incentive param" do
      let(:truthy_visit) { {} }

      before { allow_any_instance_of(described_class).to receive(:current_visit).and_return(truthy_visit) }

      context "when '1' passed as cash_incentive param" do
        let(:url_params) { { locale: "de", cash_incentive: "1" } }

        it "sets mandate.info['cash_incentive'] to true" do
          get :new, params: url_params
          subject

          mandate = User.last.mandate
          expect(mandate.info["cash_incentive"]).to be(true)
        end
      end

      context "when cash_incentive param is NOT passed" do
        let(:url_params) { { locale: "de" } }

        it "does NOT touch mandate.info['cash_incentive'] and mandate.network" do
          get :new, params: url_params
          subject

          mandate = User.last.mandate
          expect(mandate.info["cash_incentive"]).to be_nil
        end
      end
    end
  end

  describe "#fairtravel" do
    context "redirection" do
      context "with query params" do
        it "should redirect to correct url with query params" do
          get :fairtravel, params: { locale: "de", partner: "MilesAndMore", utm_source: "outbrain" }
          expect(response)
            .to redirect_to(/\/de\/app\/mandate\/partner\/fairtravel\?partner=MilesAndMore&utm_source=outbrain/)
        end
      end

      context "without query params" do
        it "should redirect to correct url" do
          get :fairtravel, params: { locale: "de" }
          expect(response).to redirect_to(/\/de\/app\/mandate\/partner\/fairtravel/)
        end
      end
    end

    context "adding adjust and partner data" do
      it "should call respective methods" do
        expect(controller).to receive(:add_adjust_data_to_lead)
        expect(controller).to receive(:add_partner_data_to_lead)
        get :fairtravel, params: { locale: "de" }
      end
    end
  end
end
