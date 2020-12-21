# frozen_string_literal: true

require "rails_helper"
RSpec.describe Domain::Leads::LeadBuilder do
  let(:lead) { create(:lead, adjust: {}) }
  let(:subject) { described_class.new(lead) }
  let(:ahoy_visit) { create(:tracking_visit) }

  describe "ensure_adjust" do
    context "when lead has no adjust data" do
      let(:lead) { create(:lead) }

      it "sets lead's adjust to empty hash" do
        subject.send(:ensure_adjust)
        expect(lead.adjust).to eq({})
      end
    end

    context "when lead has adjust data" do
      let(:network) { "some" }
      let(:lead) { create(:lead, adjust: { network: network }) }

      it "does NOT update lead's adjust data" do
        subject.send(:ensure_adjust)
        expect(lead.adjust["network"]).to eq(network)
      end
    end
  end

  describe "add_basic_metadata" do
    it "maps utm_source from visit to network if present" do
      utm_source = "fake source"
      ahoy_visit["utm_source"] = utm_source
      subject.send(:add_basic_metadata, ahoy_visit)
      expect(lead.adjust["network"]).to eq(utm_source)
    end

    it "maps utm_campaign from visit to campaign if present" do
      utm_campaign = "fake campaign"
      ahoy_visit["utm_campaign"] = utm_campaign
      subject.send(:add_basic_metadata, ahoy_visit)
      expect(lead.adjust["campaign"]).to eq(utm_campaign)
    end

    it "maps utm_medium from visit to medium if present" do
      utm_medium = "fake medium"
      ahoy_visit["utm_medium"] = utm_medium
      subject.send(:add_basic_metadata, ahoy_visit)
      expect(lead.adjust["medium"]).to eq(utm_medium)
    end

    it "maps utm_term from visit to creative if present" do
      utm_term = "fake term"
      ahoy_visit["utm_term"] = utm_term
      subject.send(:add_basic_metadata, ahoy_visit)
      expect(lead.adjust["creative"]).to eq(utm_term)
    end

    it "maps utm_content from visit to adgroup if present" do
      utm_content = "fake content"
      ahoy_visit["utm_content"] = utm_content
      subject.send(:add_basic_metadata, ahoy_visit)
      expect(lead.adjust["adgroup"]).to eq(utm_content)
    end
  end

  describe "add_network_from_landing" do
    let(:ahoy_visit) { create(:tracking_visit, landing_page: landing_page) }

    context "when landing page matches mapping" do
      let(:landing_page) { "http://localhost:3000/de/cms/payback" }
      let(:network_from_landing) { "payback" }

      context "when lead's adjust network is NOT set" do
        it "sets lead's adjust network to corresponding network from landing mapping" do
          subject.send(:add_network_from_landing, ahoy_visit)
          expect(lead.network).to eq(network_from_landing)
        end
      end

      context "when lead's adjust network is already set" do
        let(:lead) { create(:lead, adjust: { network: "some" }) }

        it "does NOT change lead's adjust network" do
          expect {
            subject.send(:add_network_from_landing, ahoy_visit)
          }.not_to change(lead, :network)
        end
      end
    end

    context "when landing page does NOT match mapping" do
      let(:landing_page) { "http://localhost:3000/de/" }

      it "does NOT change lead's adjust network" do
        expect {
          subject.send(:add_network_from_landing, ahoy_visit)
        }.not_to change(lead, :network)
      end
    end
  end

  describe "add_partner_id" do
    let(:pc_id) { "123" }
    let(:campaign_landing_page_with_pc_id) {
      "http://localhost/de/?utm_source=disney&utm_campaign=Feb17&utm_medium=BrandPage&pc_id=#{pc_id}&utm_term=banner"
    }
    let(:campaign_landing_page_without_pc_id) {
      "http://localhost/de/?utm_source=disney&utm_campaign=Feb17&utm_medium=BrandPage&utm_term=banner"
    }

    it "adds the partner customer id to lead if it can find pc_id in the landing page in the tracking visit" do
      ahoy_visit["landing_page"] = campaign_landing_page_with_pc_id
      subject.send(:add_partner_id, ahoy_visit)
      expect(lead.partner_customer_id).to eq(pc_id)
    end

    it "defaults the partner customer id to nil if it can not find pc_id in the landing page in the tracking visit" do
      ahoy_visit["landing_page"] = campaign_landing_page_without_pc_id
      subject.send(:add_partner_id, ahoy_visit)
      expect(lead.partner_customer_id).to be_nil
    end
  end

  describe "add_external_metadata" do
    let(:mapped_referrer) { Domain::Partners::PartnerIdentification::PARTNERS_MAPPING.keys.first }
    let(:fb_click_id) { "123" }
    let(:landing_page_with_fb_click) {
      "www.localhost/de?referrer=#{mapped_referrer}&utm_source=#{mapped_referrer}&fblick_id=#{fb_click_id}"
    }

    it "maps the referrer mapping to the network if referrer exist in the ahoy visit and has a mapping" do
      ahoy_visit["referrer"] = mapped_referrer
      subject.send(:add_external_metadata, ahoy_visit, nil)
      expect(lead.adjust["network"]).to eq(Domain::Partners::PartnerIdentification::PARTNERS_MAPPING[mapped_referrer])
    end

    it "leaves network as nil if referrer has no mapping" do
      referrer = "not mapped"
      ahoy_visit["referrer"] = referrer
      subject.send(:add_external_metadata, ahoy_visit, nil)
      expect(lead.adjust["network"]).to be_nil
    end

    it "doesn't add fblick_id if the passed referrer is unmapped to a partner" do
      referrer = "not mapped"
      subject.send(:add_external_metadata, ahoy_visit, referrer)
      expect(lead.source_data["fblick_id"]).to be_nil
    end

    it "maps fblick_id from fblick_id in the landing page in the ahoy visit" do
      ahoy_visit["landing_page"] = landing_page_with_fb_click
      subject.send(:add_external_metadata, ahoy_visit, mapped_referrer)
      expect(lead.source_data["fblick_id"]).to eq(fb_click_id)
      expect(lead.source_data["referrer"]).to eq(mapped_referrer)
      expect(lead.inviter_code).to eq(mapped_referrer)
    end
  end

  describe "update_network_if_referral_program" do
    let(:referral_code) { "12345" }

    it "doesn't add inviter_code if passed referral_code is nil" do
      subject.send(:update_network_if_referral_program, nil)
      expect(lead.inviter_code).to be_nil
    end

    it "adds the inviter_code if passed referral_code" do
      subject.send(:update_network_if_referral_program, referral_code)
      expect(lead.inviter_code).to eq(referral_code)
    end

    it "changes the network to referral program if passed referral_code" do
      subject.send(:update_network_if_referral_program, referral_code)
      expect(lead.adjust["network"]).to eq("referral program")
    end
  end

  describe "add_session_based_metadata" do
    let(:session) { {} }

    context "when session with mapped partner landing page" do
      let(:landing_page) { described_class::PARTNER_NETWORK_TOKENS.keys.first }

      before do
        session[:latest_landing_page] = landing_page
      end

      it "sets the network of mandate metadata to partner mapping if session landing page exists and can be mapped" do
        subject.send(:add_session_based_metadata, session)
        expect(lead.adjust["network"]).to eq(described_class::PARTNER_NETWORK_TOKENS[landing_page])
      end

      it "maps latest_utm_campaign to the lead campaign attribute" do
        campaign = "fake campaign"
        session[:latest_utm_campaign] = campaign
        subject.send(:add_session_based_metadata, session)
        expect(lead.adjust["campaign"]).to eq(campaign)
      end

      it "maps latest_utm_medium to the lead creative attribute" do
        medium = "fake medium"
        session[:latest_utm_medium] = medium
        subject.send(:add_session_based_metadata, session)
        expect(lead.adjust["medium"]).to eq(medium)
      end

      it "maps latest_utm_content to the lead adgroup attribute" do
        content = "fake content"
        session[:latest_utm_content] = content
        subject.send(:add_session_based_metadata, session)
        expect(lead.adjust["adgroup"]).to eq(content)
      end

      it "maps latest_utm_term to the lead creative attribute" do
        creative = "fake creative"
        session[:latest_utm_term] = creative
        subject.send(:add_session_based_metadata, session)
        expect(lead.adjust["creative"]).to eq(creative)
      end

      it "sets the adgroup to nil" do
        lead.adjust["adgroup"] = "fake ad group"
        subject.send(:add_session_based_metadata, session)
        expect(lead.adjust["adgroup"]).to be_nil
      end
    end

    context "when session with landing page unmapped to a partner" do
      let(:landing_page) { "unmapped" }

      before do
        session[:latest_landing_page] = landing_page
      end

      it "leaves the network of the lead untouched" do
        subject.send(:add_session_based_metadata, session)
        expect(lead.adjust["network"]).to be_nil
      end
    end
  end

  describe "update_mandate!" do
    it "defaults the mandate owner ident to clark if the lead didn't have any data in the network attribute" do
      subject.send(:update_mandate!)
      expect(lead.mandate.owner_ident).to eq("clark")
    end

    it "defaults the mandate owner ident to clark if the lead have a network but unmapped to an owner" do
      lead.adjust["network"] = "un mapped to owner"
      subject.send(:update_mandate!)
      expect(lead.mandate.owner_ident).to eq("clark")
    end

    it "sets the mandate owner ident if the lead network attribute can be mapped to an owner" do
      lead.adjust["network"] = described_class::OWNER_MAPPING.keys.first
      subject.send(:update_mandate!)
      expect(lead.mandate.owner_ident).to eq(described_class::OWNER_MAPPING.values.first)
    end

    it "does NOT set mandate's sovendus token if network is NOT sovendus" do
      subject.send(:update_mandate!)
      expect(lead.mandate.info["sovendus_request_token"]).to be_nil
    end

    it "sets mandate's sovendus token if network is sovendus" do
      token = "some_token"
      lead.adjust["network"] = OutboundChannels::Sovendus::SOVENDUS_MANDATE_SOURCE
      lead.adjust["adgroup"] = token
      subject.send(:update_mandate!)
      expect(lead.mandate.info["sovendus_request_token"]).to eq(token)
    end
  end
end
