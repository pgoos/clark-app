# frozen_string_literal: true

require "rails_helper"

RSpec.describe Report::Voucher::PayoutRepository, :integration do
  subject { described_class.new }

  let(:voucher) { create(:voucher) }
  let(:gvk_plan) { create(:plan, category: create(:category, id: 33)) }
  let(:grv_plan) { create(:plan, category: create(:category, id: 237)) }

  let(:gvk_product) { create(:product, plan: gvk_plan) }
  let(:grv_product) { create(:product, plan: grv_plan) }

  let(:mandate) do
    create(
      :mandate,
      voucher: voucher,
      products: [gvk_product, grv_product],
      opportunities: [create(:opportunity, category_id: 33, state: "completed")]
    )
  end
  let(:adjust) { {campaign: "campaign", adgroup: "adgroup", creative: "creative"} }

  let!(:user) { create(:user, mandate: mandate, source_data: {adjust: adjust}) }

  let!(:business_event) { create(:business_event, action: "accept", person: user, entity: mandate) }

  let(:expected_response) do
    {
      "mandate_id" => mandate.id,
      "mandate_state" => mandate.state,
      "first_name" => mandate.first_name,
      "last_name" => mandate.last_name,
      "street" => mandate.street,
      "house_number" => mandate.house_number,
      "zipcode" => mandate.zipcode,
      "city" => mandate.city,
      "email" => user.email,
      "gave_us_iban" => false,
      "utm_source" => nil,
      "utm_campaign" => "campaign",
      "utm_content" => "adgroup",
      "utm_term" => "creative",
      "voucher_code" => voucher.code,
      "cpa_cents" => "1000",
      "count_products_under_management_correspondence_details_availabl" => 2,
      "count_gkv_products" => 1,
      "count_grv_products" => 1,
      "count_completed_high_margin_opportunities" => 1,
      "count_completed_low_margin_opportunities" => 0,
      "birthdate" => mandate.birthdate.utc.strftime("%Y-%m-%d %H:%M:%S"),
      "mandate_accepted_at" => business_event.created_at.utc.strftime("%Y-%m-%d %H:%M:%S.%6N").sub!(/0*$/, "")
    }
  end

  describe "#all" do
    it "returns correct report" do
      report = subject.all

      expect(report.size).to eq(1)

      expect(report.first).to eq(expected_response)
    end
  end
end
