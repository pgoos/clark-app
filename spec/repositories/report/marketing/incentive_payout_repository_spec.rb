# frozen_string_literal: true

require "rails_helper"

RSpec.describe Report::Marketing::IncentivePayoutRepository do
  subject { described_class.new }

  let!(:user) { create(:user, source_data: {adjust: {network: "mam", campaign: "tmx-2430", adgroup: "some_group"}}) }
  let!(:voucher) { create(:voucher) }
  let!(:mandate) { create(:mandate, :accepted, user: user, voucher_id: voucher.id) }
  let!(:advertiser_channel_mapping) { create(:advertiser_channel_mapping, ad_provider: "mam") }
  let!(:accepted_event) { create(:business_event, entity_type: "Mandate", action: "accept", entity_id: mandate.id) }

  describe "#all" do
    it "returns the correct result" do
      expect(subject.all.size).to eq(1)
      expect(subject.all.first["mandate_id"]).to eq(mandate.id)
      expect(subject.all.first["voucher_id"]).to eq(voucher.id)
      expect(subject.all.first["adgroup"]).to eq(user.source_data["adjust"]["adgroup"])
      expect(subject.all.first["accepted_at"]).to eq(accepted_event.created_at.strftime("%Y-%m-%d"))
    end
  end

  context "generated SQL" do
    let(:first_deal_design_campaigns) { %w[shoop-0822 questler-0120] }
    let(:second_deal_design_campaigns) { %w[amazon100] }
    let!(:deal_designs_json) {
      [
        {
          "name" => "Amazon50",
          "based_on" => "products",
          "mandate_state" => "accepted",
          "min_for_reward" => 2,
          "include_gkv_grv" => false,
          "layering_payout_min" => 50,
          "layering_payout_additional" => 0,
          "layering_maximum" => 50,
          "campaigns" => first_deal_design_campaigns
        },
        {
          "name" => "Amazon100",
          "based_on" => "inquiries",
          "mandate_state" => "accepted",
          "min_for_reward" => 3,
          "include_gkv_grv" => false,
          "layering_payout_min" => 20,
          "layering_payout_additional" => 10,
          "layering_maximum" => 100,
          "campaigns" => second_deal_design_campaigns
        }
      ]
    }

    before do
      allow_any_instance_of(described_class)
        .to receive(:fetch_deal_designs_json).and_return(deal_designs_json)
    end

    describe "#generate_campaigns_from_config" do
      it "returns all the campaigns defined in the deal designs json elements" do
        expect(subject.send(:generate_campaigns_from_config))
          .to eq("'#{(first_deal_design_campaigns + second_deal_design_campaigns).join("','")}'")
      end
    end

    describe "#generate_layering_payout_from_config" do
      it "generates the right layering sql from the json config" do
        expect(subject.send(:generate_layering_payout_from_config))
          .to eq("
            -- Rule Name: 'Amazon50'
            WHEN user_source_data.campaign IN ('#{first_deal_design_campaigns.join("','")}')
              AND mandates.state = 'accepted'
                AND count_products.count_created_products_excl_certain_categories >= 2
                THEN least(50 + (count_products.count_created_products_excl_certain_categories - 2) * 0, 50)
            -- Rule Name: 'Amazon100'
            WHEN user_source_data.campaign IN ('#{second_deal_design_campaigns.join("','")}')
              AND mandates.state = 'accepted'
                AND count_category_inquiries.count_category_inquiries_excl_certain_categories >= 3
                THEN least(20 + (count_category_inquiries.count_category_inquiries_excl_certain_categories - 3) * 10, 100)"
              )
      end
    end
  end
end
