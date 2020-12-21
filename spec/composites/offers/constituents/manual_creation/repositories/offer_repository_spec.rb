# frozen_string_literal: true

require "rails_helper"
require "composites/offers/constituents/manual_creation/repositories/offer_repository"

RSpec.describe Offers::Constituents::ManualCreation::Repositories::OfferRepository, :integration do
  subject { described_class.new }

  let(:opportunity) { create(:opportunity) }
  let(:plan) { create(:plan, :activated, :with_stubbed_coverages) }
  let(:plan2) { create(:plan, :activated, :with_stubbed_coverages) }

  let(:displayed_coverage_features) do
    %w[
      dckngc12f5331a9f374fb
      dckng7eecd7eff390d702
      dckng9ff71af780194301
    ]
  end

  let(:offer_options_attributes) do
    [
      {
        "option_type" => "",
        "recommended" => "1",
        "product_attributes" => {
          "plan_ident" =>  plan.ident,
          "premium_price" => "10,00",
          "premium_period" => "year",
          "contract_started_at" => "2014-11-20 17:21:19 +0100",
          "contract_ended_at" => "",
          "coverages" => {
            "dckngc12f5331a9f374fb" => {
              "value" => "10000000",
              "currency" => "EUR",
              "type" => "Money"
            },
            "dckng7eecd7eff390d702" => {
              "value" => "10000000",
              "currency" => "EUR",
              "type" => "Money"
            },
            "dckng9ff71af780194301" => {
              "value" => "10000000",
              "currency" => "EUR",
              "type" => "Money"
            },
            "slbstb20c96d0873b5416" => {
              "value" => "0",
              "currency" => "EUR",
              "type" => "Money"
            },
            "boolean_frdrngssflldckng_aae584" => {
              "value" => "",
              "type" => "Boolean"
            },
            "boolean_mtvrschrngkndr_1bbedb" => {
              "value" => "",
              "type" => "Boolean"
            },
            "bhndn96c4a408147d8fa6" => {
              "value" => "",
              "currency" => "EUR",
              "type" => "Money"
            },
            "boolean_mtvrschrnghhnlchlbnsprtnr_96c32c" => {
              "value" => "",
              "type" => "Boolean"
            },
            "schlüd33b8177f4c8c39a" => {
              "value" => "",
              "currency" => "EUR",
              "type" => "Money"
            },
            "dckng83b920a96cb5bee7" => {
              "value" => "",
              "currency" => "EUR",
              "type" => "Money"
            },
            "boolean_mtvrschrngslbstbwhntgndrgmttmmblnnlnd_54d96f" => {
              "value" => "",
              "type" => "Boolean"
            },
            "boolean_mtvrschrngslbstbwhntgndrgmttmmblnslnd_99c7d0" => {
              "value" => "",
              "type" => "Boolean"
            },
            "boolean_mtvrschrngvrmttmmblnnlndnlgrwhnngfrnwhnngnzlnzmmr_85dd90" => {
              "value" => "",
              "type" => "Boolean"
            },
            "boolean_mtvrschrngvrmttmmblnslndnlgrwhnngfrnwhnngnzlnzmmr_d8a0ff" => {
              "value" => "",
              "type" => "Boolean"
            },
            "dckng27dd7222e844b420" => {
              "value" => "",
              "currency" => "EUR",
              "type" => "Money"
            },
            "int_mtvrschrngnbbtgrndstck_e66184" => {
              "int" => "",
              "type" => "Int"
            },
            "boolean_mtvrschrngphtvltknlg_ceae25" => {
              "value" => "",
              "type" => "Boolean"
            },
            "boolean_mtvrschrnghrnmtlchttgktn_b7fa61" => {
              "value" => "",
              "type" => "Boolean"
            },
            "dckng54080a884e3374be" => {
              "value" => "1000",
              "currency" => "EUR",
              "type" => "Money"
            },
            "int_slndsfnthltnnrhlbrp_af1614" => {
              "int" => "",
              "type" => "Int"
            },
            "int_slndsfnthltrhlbrp_590e50" => {
              "int" => "",
              "type" => "Int"
            },
            "int_mtvrschrnggnrsglbt_a6531b" => {
              "int" => "",
              "type" => "Int"
            },
            "int_mtvrschrnggnrmtrbt_75927e" => {
              "int" => "",
              "type" => "Int"
            },
            "boolean_lktrnschrdtnstschntrntntzng_245272" => {
              "value" => "TRUE",
              "type" => "Boolean"
            },
            "dckng699550c04ed99714" => {
              "value" => "15000",
              "currency" => "EUR",
              "type" => "Money"
            },
            "dckngbc9efa9c1d61539b" => {
              "value" => "",
              "currency" => "EUR",
              "type" => "Money"
            },
            "boolean_bhndnkmmnfrmdrschn_0094c2" => {
              "value" => "",
              "type" => "Boolean"
            },
            "boolean_bschdgngfrmdrbwglchrschngmttgpchttglhn_6f3a50" => {
              "value" => "",
              "type" => "Boolean"
            },
            "boolean_bndntldschdn_84eff7" => {
              "value" => "",
              "type" => "Boolean"
            },
            "boolean_dnsthftpflchtvrschrng_18bc91" => {
              "value" => "",
              "type" => "Boolean"
            },
            "text_drhnnkptr_001bc2" => {
              "text" => "",
              "type" => "Text"
            }
          }
        }
      },
      {
        "option_type" => "",
        "recommended" => "0",
        "product_attributes" => {
          "plan_ident" =>  plan2.ident,
          "premium_price" => "20,00",
          "premium_period" => "year",
          "contract_started_at" => "2014-11-20 17:21:19 +0100",
          "contract_ended_at" => "",
          "coverages" => {
            "dckngc12f5331a9f374fb" => {
              "value" => "20000000",
              "currency" => "EUR",
              "type" => "Money"
            },
            "dckng7eecd7eff390d702" => {
              "value" => "10000000",
              "currency" => "EUR",
              "type" => "Money"
            },
            "dckng9ff71af780194301" => {
              "value" => "10000000",
              "currency" => "EUR",
              "type" => "Money"
            },
            "slbstb20c96d0873b5416" => {
              "value" => "0",
              "currency" => "EUR",
              "type" => "Money"
            },
            "boolean_frdrngssflldckng_aae584" => {
              "value" => "",
              "type" => "Boolean"
            },
            "boolean_mtvrschrngkndr_1bbedb" => {
              "value" => "",
              "type" => "Boolean"
            },
            "bhndn96c4a408147d8fa6" => {
              "value" => "",
              "currency" => "EUR",
              "type" => "Money"
            },
            "boolean_mtvrschrnghhnlchlbnsprtnr_96c32c" => {
              "value" => "",
              "type" => "Boolean"
            },
            "schlüd33b8177f4c8c39a" => {
              "value" => "",
              "currency" => "EUR",
              "type" => "Money"
            },
            "dckng83b920a96cb5bee7" => {
              "value" => "",
              "currency" => "EUR",
              "type" => "Money"
            },
            "boolean_mtvrschrngslbstbwhntgndrgmttmmblnnlnd_54d96f" => {
              "value" => "",
              "type" => "Boolean"
            },
            "boolean_mtvrschrngslbstbwhntgndrgmttmmblnslnd_99c7d0" => {
              "value" => "",
              "type" => "Boolean"
            },
            "boolean_mtvrschrngvrmttmmblnnlndnlgrwhnngfrnwhnngnzlnzmmr_85dd90" => {
              "value" => "",
              "type" => "Boolean"
            },
            "boolean_mtvrschrngvrmttmmblnslndnlgrwhnngfrnwhnngnzlnzmmr_d8a0ff" => {
              "value" => "",
              "type" => "Boolean"
            },
            "dckng27dd7222e844b420" => {
              "value" => "",
              "currency" => "EUR",
              "type" => "Money"
            },
            "int_mtvrschrngnbbtgrndstck_e66184" => {
              "int" => "",
              "type" => "Int"
            },
            "boolean_mtvrschrngphtvltknlg_ceae25" => {
              "value" => "",
              "type" => "Boolean"
            },
            "boolean_mtvrschrnghrnmtlchttgktn_b7fa61" => {
              "value" => "",
              "type" => "Boolean"
            },
            "dckng54080a884e3374be" => {
              "value" => "1000",
              "currency" => "EUR",
              "type" => "Money"
            },
            "int_slndsfnthltnnrhlbrp_af1614" => {
              "int" => "",
              "type" => "Int"
            },
            "int_slndsfnthltrhlbrp_590e50" => {
              "int" => "",
              "type" => "Int"
            },
            "int_mtvrschrnggnrsglbt_a6531b" => {
              "int" => "",
              "type" => "Int"
            },
            "int_mtvrschrnggnrmtrbt_75927e" => {
              "int" => "",
              "type" => "Int"
            },
            "boolean_lktrnschrdtnstschntrntntzng_245272" => {
              "value" => "TRUE",
              "type" => "Boolean"
            },
            "dckng699550c04ed99714" => {
              "value" => "15000",
              "currency" => "EUR",
              "type" => "Money"
            },
            "dckngbc9efa9c1d61539b" => {
              "value" => "",
              "currency" => "EUR",
              "type" => "Money"
            },
            "boolean_bhndnkmmnfrmdrschn_0094c2" => {
              "value" => "",
              "type" => "Boolean"
            },
            "boolean_bschdgngfrmdrbwglchrschngmttgpchttglhn_6f3a50" => {
              "value" => "",
              "type" => "Boolean"
            },
            "boolean_bndntldschdn_84eff7" => {
              "value" => "",
              "type" => "Boolean"
            },
            "boolean_dnsthftpflchtvrschrng_18bc91" => {
              "value" => "",
              "type" => "Boolean"
            },
            "text_drhnnkptr_001bc2" => {
              "text" => "",
              "type" => "Text"
            }
          }
        }
      }
    ]
  end

  let(:note_to_customer) { "Some note to the customer \n with several \n lines" }

  let(:documents_attributes) do
    {
      "0" => { "document_type_id" => "49" }
    }
  end

  let(:offer_parameters) do
    {
      displayed_coverage_features: displayed_coverage_features,
      offer_options_attributes: offer_options_attributes,
      note_to_customer: note_to_customer,
      documents_attributes: documents_attributes,
      opportunity_id: opportunity.id
    }
  end

  describe "#create!" do
    it "returns new offer entity" do
      result = subject.create!(offer_parameters)
      created_offer = opportunity.reload.offer
      creted_offer_options = OfferOption.where(offer_id: created_offer)
      created_products = Product.where(id: creted_offer_options.map(&:product_id))

      expect(result.id).to eq(created_offer.id)
      expect(result.customer_id).to eq(created_offer.mandate_id)
      expect(result.state).to eq(created_offer.state)
      expect(result.offered_on).to eq(created_offer.offered_on)
      expect(result.valid_until).to eq(created_offer.valid_until)
      expect(result.note_to_customer).to eq(created_offer.note_to_customer)
      expect(result.displayed_coverage_features).to eq(created_offer.displayed_coverage_features)
      expect(result.active_offer_selected).to eq(created_offer.active_offer_selected)
      expect(result.info).to eq(created_offer.info)
      expect(result.offer_rule_id).to eq(created_offer.offer_rule_id)
      expect(result.offer_options).not_to be_empty

      expect(creted_offer_options.count).to eq(2)
      expect(created_products.first.state).to eq("offered")
      expect(created_products.last.state).to eq("offered")

      offer_option = result.offer_options.first
      expect(offer_option).to be_a(Offers::Constituents::ManualCreation::Entities::OfferOption)
      created_offer_option = created_offer.offer_options.first
      expect(offer_option.premium_price_cents).to eq created_offer_option.product.premium_price_cents
      expect(offer_option.premium_price_currency).to eq created_offer_option.product.premium_price_currency
      expect(offer_option.premium_period).to eq created_offer_option.product.premium_period
      expect(offer_option.offer_option_id).to eq created_offer_option.id
      expect(offer_option.contract_start).to eq created_offer_option.product.contract_started_at
      expect(offer_option.contract_end).to eq created_offer_option.product.contract_ended_at
      expect(offer_option.option_type).to eq created_offer_option.option_type
    end
  end

  describe "#update!" do
    let(:mandate) { create(:mandate) }
    let(:offer) { create(:active_offer, mandate: mandate) }

    it "updates offer entity" do
      offer_options_attributes.each_with_index do |attrs, index|
        attrs.merge!(id: offer.offer_options[index].id)
      end

      offer_parameters.delete(:opportunity_id)

      result = subject.update!(offer_parameters.merge(id: offer.id))
      updated_offer = offer.reload

      expect(result.id).to eq(updated_offer.id)
      expect(result.customer_id).to eq(updated_offer.mandate_id)
      expect(result.state).to eq(updated_offer.state)
      expect(result.offered_on).to eq(updated_offer.offered_on)
      expect(result.valid_until).to eq(updated_offer.valid_until)
      expect(result.note_to_customer).to eq(updated_offer.note_to_customer)
      expect(result.displayed_coverage_features).to eq(updated_offer.displayed_coverage_features)
      expect(result.active_offer_selected).to eq(updated_offer.active_offer_selected)
      expect(result.info).to eq(updated_offer.info)
      expect(result.offer_rule_id).to eq(updated_offer.offer_rule_id)
    end
  end
end
