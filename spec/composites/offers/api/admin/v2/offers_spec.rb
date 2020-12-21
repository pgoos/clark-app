# frozen_string_literal: true

require "swagger_helper"

describe ::Offers::Api::Admin::V2::Offers, type: :request, integration: true, swagger_doc: "v2/admin.yaml" do
  let("Content-Type".to_sym) { "application/json" }
  let(:accept) { "application/vnd.clark-admin-v2+json" }
  let!(:plan) { create(:plan, :activated, :with_stubbed_coverages) }
  let(:admin) { create(:admin) }

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
        "option_type" => "top_cover",
        "recommended" => "1",
        "product_attributes" => {
          "id" => "",
          "plan_ident" =>  plan.ident,
          "premium_price" => "10,00",
          "premium_period" => "year",
          "contract_started_at" => Time.zone.today.strftime("%Y-%m-%d"),
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
      }
    ]
  end

  let(:note_to_customer) do
    "<h2>Note title</h2>
    <p>\t Note description \n with several \n lines</p>"
  end

  let(:documents_attributes) do
    {
      "0" => { "document_type_id" => "49" }
    }
  end

  path "/api/admin/offers/manual_creation/offers/{opportunity_id}" do
    post "Create offer" do
      consumes "application/json"
      parameter name: :opportunity_id, in: :path, type: :string, description: "Contract ID"
      parameter name: :body, in: :body, type: :object, description: "Offers parameters"
      parameter name: :accept, in: :header, schema: { type: :string }
      parameter name: "Content-Type".to_sym, in: :header, schema: { type: :string }

      response "401", "without authorization" do
        let!(:customer) { create(:customer) }
        let!(:opportunity) { create(:opportunity, mandate_id: customer.id) }
        let!(:opportunity_id) { opportunity.id }

        let!(:body) do
          {
            displayed_coverage_features: displayed_coverage_features,
            offer_options_attributes: offer_options_attributes,
            note_to_customer: note_to_customer,
            documents_attributes: documents_attributes
          }
        end

        run_test!
      end

      response "422", "non-existing opportunity" do
        let!(:customer) { create(:customer) }
        let!(:opportunity_id) { 53_298_705_523 }
        let!(:authentication) { login_as(admin, scope: :admin) }

        let!(:body) do
          {
            displayed_coverage_features: displayed_coverage_features,
            offer_options_attributes: offer_options_attributes,
            note_to_customer: note_to_customer,
            documents_attributes: documents_attributes
          }
        end

        run_test!
      end

      response "422", "Note to customer is too long" do
        let!(:customer) { create(:customer) }
        let!(:opportunity_id) { 53_298_705_523 }
        let!(:authentication) { login_as(admin, scope: :admin) }
        let(:note_to_customer) { Faker::String.random(1500 + 1) }

        let!(:body) do
          {
            displayed_coverage_features: displayed_coverage_features,
            offer_options_attributes: offer_options_attributes,
            note_to_customer: note_to_customer,
            documents_attributes: documents_attributes
          }
        end

        run_test! do |_response|
          translation = I18n.t("activerecord.errors.models.offer.attributes.note_to_customer.max_length")
          expect(json_response[:error]).to eq([translation])
        end
      end

      response "422", "Coverage feature is empty and visible" do
        let!(:customer) { create(:customer) }
        let!(:opportunity_id) { 53_298_705_523 }
        let!(:authentication) { login_as(admin, scope: :admin) }

        let!(:options_attributes) do
          offer_options_attributes.first["product_attributes"]["coverages"].tap do |attrs|
            attrs[displayed_coverage_features.first]["value"] = nil
          end
        end

        let!(:body) do
          {
            displayed_coverage_features: displayed_coverage_features,
            offer_options_attributes: offer_options_attributes,
            note_to_customer: note_to_customer,
            documents_attributes: documents_attributes
          }
        end

        run_test! do |_response|
          translation = I18n.t(
            "dry_validation.errors.offers.constituents.manual_creation.coverages.should_exist_if_visible"
          )
          expect(json_response[:error]).to eq([translation])
        end
      end

      response "422", "Offer options 'option_type' is empty" do
        let!(:customer) { create(:customer) }
        let!(:opportunity) { create(:opportunity, mandate_id: customer.id) }
        let!(:opportunity_id) { opportunity.id }
        let!(:authentication) { login_as(admin, scope: :admin) }

        let!(:offer_options_attributes_without_option_type) do
          offer_options_attributes.map do |opt_attributes|
            opt_attributes["option_type"] = ""
            opt_attributes
          end
        end

        let!(:body) do
          {
            displayed_coverage_features: displayed_coverage_features,
            offer_options_attributes: offer_options_attributes_without_option_type,
            note_to_customer: note_to_customer,
            documents_attributes: documents_attributes
          }
        end

        run_test! do |_response|
          translation = I18n.t("dry_validation.errors.rules.option_type.filled?")
          expect(json_response[:error])
            .to include({ "0" => { "option_type" => [translation] } })
        end
      end

      response "422", "Offer options 'plan_ident' is empty" do
        let!(:customer) { create(:customer) }
        let!(:opportunity) { create(:opportunity, mandate_id: customer.id) }
        let!(:opportunity_id) { opportunity.id }
        let!(:authentication) { login_as(admin, scope: :admin) }

        let!(:offer_options_attributes_without_plan) do
          offer_options_attributes.map do |opt_attributes|
            opt_attributes["product_attributes"]["plan_ident"] = ""
            opt_attributes
          end
        end

        let!(:body) do
          {
            displayed_coverage_features: displayed_coverage_features,
            offer_options_attributes: offer_options_attributes_without_plan,
            note_to_customer: note_to_customer,
            documents_attributes: documents_attributes
          }
        end

        run_test! do |_response|
          translation = I18n.t("dry_validation.errors.rules.plan_ident.filled?")
          expect(json_response[:error])
            .to include({ "0" => { "product_attributes" => { "plan_ident" => [translation] } } })
        end
      end

      response "422", "Offer options 'premium_price' is empty" do
        let!(:customer) { create(:customer) }
        let!(:opportunity) { create(:opportunity, mandate_id: customer.id) }
        let!(:opportunity_id) { opportunity.id }
        let!(:authentication) { login_as(admin, scope: :admin) }

        let!(:offer_options_attributes_without_premium_price) do
          offer_options_attributes.map do |opt_attributes|
            opt_attributes["product_attributes"]["premium_price"] = ""
            opt_attributes
          end
        end

        let!(:body) do
          {
            displayed_coverage_features: displayed_coverage_features,
            offer_options_attributes: offer_options_attributes_without_premium_price,
            note_to_customer: note_to_customer,
            documents_attributes: documents_attributes
          }
        end

        run_test! do |_response|
          translation = I18n.t("dry_validation.errors.rules.premium_price.filled?")
          expect(json_response[:error])
            .to include({ "0" => { "product_attributes" => { "premium_price" => [translation] } } })
        end
      end

      response "422", "Offer options 'premium_price' is not positive" do
        let!(:customer) { create(:customer) }
        let!(:opportunity) { create(:opportunity, mandate_id: customer.id) }
        let!(:opportunity_id) { opportunity.id }
        let!(:authentication) { login_as(admin, scope: :admin) }

        let!(:offer_options_attributes_without_premium_price) do
          offer_options_attributes.map do |opt_attributes|
            opt_attributes["product_attributes"]["premium_price"] = "-1"
            opt_attributes
          end
        end

        let!(:body) do
          {
            displayed_coverage_features: displayed_coverage_features,
            offer_options_attributes: offer_options_attributes_without_premium_price,
            note_to_customer: note_to_customer,
            documents_attributes: documents_attributes
          }
        end

        run_test! do |_response|
          translation = I18n.t("dry_validation.errors.rules.premium_price.should_be_positive")
          expect(json_response[:error]).to include({ "0" => [translation] })
        end
      end

      response "422", "Offer options 'premium_period' is empty" do
        let!(:customer) { create(:customer) }
        let!(:opportunity) { create(:opportunity, mandate_id: customer.id) }
        let!(:opportunity_id) { opportunity.id }
        let!(:authentication) { login_as(admin, scope: :admin) }

        let!(:offer_options_attributes_without_premium_period) do
          offer_options_attributes.map do |opt_attributes|
            opt_attributes["product_attributes"]["premium_period"] = ""
            opt_attributes
          end
        end

        let!(:body) do
          {
            displayed_coverage_features: displayed_coverage_features,
            offer_options_attributes: offer_options_attributes_without_premium_period,
            note_to_customer: note_to_customer,
            documents_attributes: documents_attributes
          }
        end

        run_test! do |_response|
          translation = I18n.t("dry_validation.errors.rules.premium_period.filled?")
          expect(json_response[:error])
            .to include({ "0" => { "product_attributes" => { "premium_period" => [translation] } } })
        end
      end

      response "422", "Offer options 'contract_started_at' before current date" do
        let!(:customer) { create(:customer) }
        let!(:opportunity) { create(:opportunity, mandate_id: customer.id) }
        let!(:opportunity_id) { opportunity.id }
        let!(:authentication) { login_as(admin, scope: :admin) }

        let!(:offer_options_attributes_with_invalid_start_date) do
          offer_options_attributes.map do |opt_attributes|
            opt_attributes["product_attributes"]["contract_started_at"] = (Time.zone.today - 1.day).strftime("%Y-%m-%d")
            opt_attributes
          end
        end

        let!(:body) do
          {
            displayed_coverage_features: displayed_coverage_features,
            offer_options_attributes: offer_options_attributes_with_invalid_start_date,
            note_to_customer: note_to_customer,
            documents_attributes: documents_attributes
          }
        end

        run_test! do |_response|
          translation = I18n.t("dry_validation.errors.rules.contract_started_at.before_current_date")
          expect(json_response[:error])
            .to include({ "0" => [translation] })
        end
      end

      response "422", "Offer options 'contract_ended_at' before 'contract_started_at'" do
        let!(:customer) { create(:customer) }
        let!(:opportunity) { create(:opportunity, mandate_id: customer.id) }
        let!(:opportunity_id) { opportunity.id }
        let!(:authentication) { login_as(admin, scope: :admin) }

        let!(:offer_options_attributes_with_invalid_end_date) do
          offer_options_attributes.map do |opt_attributes|
            opt_attributes["product_attributes"]["contract_ended_at"] = (Time.zone.today - 1.day).strftime("%Y-%m-%d")
            opt_attributes
          end
        end

        let!(:body) do
          {
            displayed_coverage_features: displayed_coverage_features,
            offer_options_attributes: offer_options_attributes_with_invalid_end_date,
            note_to_customer: note_to_customer,
            documents_attributes: documents_attributes
          }
        end

        run_test! do |_response|
          translation = I18n.t("dry_validation.errors.rules.contract_ended_at.before_contract_start")
          expect(json_response[:error])
            .to include({ "0" => [translation] })
        end
      end

      response "201", "for valid opportunity id and offer parameters" do
        let!(:customer) { create(:customer) }
        let!(:opportunity) { create(:opportunity, mandate_id: customer.id) }
        let!(:opportunity_id) { opportunity.id }
        let!(:authentication) { login_as(admin, scope: :admin) }

        let!(:body) do
          {
            displayed_coverage_features: displayed_coverage_features,
            offer_options_attributes: offer_options_attributes,
            note_to_customer: note_to_customer,
            documents_attributes: documents_attributes
          }
        end

        run_test! do |_response|
          response_data = json_response[:data][:attributes]
          created_offer = Offer.find_by_id(opportunity.reload.offer_id)
          created_product = OfferOption.find_by_offer_id(created_offer.id).product
          comment = response_data["note_to_customer"]

          expect(json_response["data"]["id"]).to eq(created_offer.id)
          expect(response_data["customer_id"]).to eq(created_offer.mandate_id)
          expect(response_data["state"]).to eq(created_offer.state)
          expect(response_data["offered_on"]).to eq(created_offer.offered_on)
          expect(response_data["valid_until"]).to eq(created_offer.valid_until)
          expect(response_data["displayed_coverage_features"]).to eq(created_offer.displayed_coverage_features)
          expect(response_data["active_offer_selected"]).to eq(created_offer.active_offer_selected)
          expect(response_data["info"]).to eq(created_offer.info)
          expect(response_data["offer_rule_id"]).to eq(created_offer.offer_rule_id)

          expect(created_product).to be_offered
          expect(created_product).to be_sold_by_us
          expect(created_product.premium_state).to eq("premium")
          expect(created_product.premium_price_currency).to eq("EUR")
          expect(created_product.number).to eq("angebotenes Produkt")

          offer_option = response_data["offer_options"].first

          expect(offer_option.keys).to match(
            %w[offer_option_id premium_price_cents premium_price_currency premium_period contract_id contract_start
               contract_end plan_ident coverages documents option_type]
          )

          expect(comment).to eq(created_offer.note_to_customer)
          expect(comment).to include("\t")
          expect(comment).to include("\n")
          expect(comment).to include("<h2>")
          expect(comment).to include("<p>")
        end
      end
    end
  end

  path "/api/admin/offers/manual_creation/offers/{id}" do
    put "Update offer" do
      consumes "application/json"
      parameter name: :id, in: :path, type: :string, description: "Offer ID"
      parameter name: :body, in: :body, type: :object, description: "Offers parameters"
      parameter name: :accept, in: :header, schema: { type: :string }
      parameter name: "Content-Type".to_sym, in: :header, schema: { type: :string }

      response "401", "without authorization" do
        let!(:customer) { create(:customer) }
        let!(:opportunity) { create(:opportunity_with_offer, mandate_id: customer.id) }
        let!(:id) { opportunity.offer_id }

        let!(:body) do
          {
            displayed_coverage_features: displayed_coverage_features,
            offer_options_attributes: offer_options_attributes,
            note_to_customer: note_to_customer,
            documents_attributes: documents_attributes
          }
        end

        run_test!
      end

      response "422", "non-existing offer" do
        let!(:customer) { create(:customer) }
        let!(:id) { 705 }
        let!(:authentication) { login_as(admin, scope: :admin) }

        let!(:body) do
          {
            displayed_coverage_features: displayed_coverage_features,
            offer_options_attributes: offer_options_attributes,
            note_to_customer: note_to_customer,
            documents_attributes: documents_attributes
          }
        end

        run_test!
      end

      response "422", "Note to customer is too long" do
        let!(:customer) { create(:customer) }
        let!(:opportunity) { create(:opportunity_with_offer, mandate_id: customer.id) }
        let!(:offer) { opportunity.offer }
        let!(:id) { offer.id }
        let!(:authentication) { login_as(admin, scope: :admin) }
        let(:note_to_customer) { Faker::String.random(1500 + 1) }

        let!(:options_attributes) do
          offer_options_attributes.tap do |attrs|
            attrs[0] = attrs[0].merge(id: offer.offer_options.find(&:recommended).id)
          end
        end

        let!(:body) do
          {
            displayed_coverage_features: displayed_coverage_features,
            offer_options_attributes: offer_options_attributes,
            note_to_customer: note_to_customer,
            documents_attributes: documents_attributes
          }
        end

        run_test! do |_response|
          translation = I18n.t("activerecord.errors.models.offer.attributes.note_to_customer.max_length")
          expect(json_response[:error]).to eq([translation])
        end
      end

      response "422", "Coverage feature is empty and visible" do
        let!(:customer) { create(:customer) }
        let!(:opportunity) { create(:opportunity_with_offer, mandate_id: customer.id) }
        let!(:offer) { opportunity.offer }
        let!(:id) { offer.id }
        let!(:authentication) { login_as(admin, scope: :admin) }

        let!(:options_attributes) do
          offer_options_attributes.tap do |attrs|
            attrs[0] = attrs[0].merge(id: offer.offer_options.find(&:recommended).id)
            attrs[0]["product_attributes"]["coverages"].tap do |product_attrs|
              product_attrs[displayed_coverage_features.first]["value"] = nil
            end
          end
        end

        let!(:body) do
          {
            displayed_coverage_features: displayed_coverage_features,
            offer_options_attributes: offer_options_attributes,
            note_to_customer: note_to_customer,
            documents_attributes: documents_attributes
          }
        end

        run_test! do |_response|
          trans_key = "dry_validation.errors.offers.constituents.manual_creation.coverages.should_exist_if_visible"
          expect(json_response[:error]).to eq([I18n.t(trans_key)])
        end
      end

      response "422", "Offer options 'option_type' is empty" do
        let!(:customer) { create(:customer) }
        let!(:opportunity) { create(:opportunity_with_offer, mandate_id: customer.id) }
        let!(:offer) { opportunity.offer }
        let!(:id) { offer.id }
        let!(:authentication) { login_as(admin, scope: :admin) }

        let!(:offer_options_attributes_without_option_type) do
          offer_options_attributes.map do |opt_attributes|
            opt_attributes["option_type"] = ""
            opt_attributes
          end
        end

        let!(:body) do
          {
            displayed_coverage_features: displayed_coverage_features,
            offer_options_attributes: offer_options_attributes_without_option_type,
            note_to_customer: note_to_customer,
            documents_attributes: documents_attributes
          }
        end

        run_test! do |_response|
          translation = I18n.t("dry_validation.errors.rules.option_type.filled?")
          expect(json_response[:error])
            .to include({ "0" => { "option_type" => [translation] } })
        end
      end

      response "422", "Offer options 'plan_ident' is empty" do
        let!(:customer) { create(:customer) }
        let!(:opportunity) { create(:opportunity_with_offer, mandate_id: customer.id) }
        let!(:offer) { opportunity.offer }
        let!(:id) { offer.id }
        let!(:authentication) { login_as(admin, scope: :admin) }

        let!(:offer_options_attributes_without_plan) do
          offer_options_attributes.map do |opt_attributes|
            opt_attributes["product_attributes"]["plan_ident"] = ""
            opt_attributes
          end
        end

        let!(:body) do
          {
            displayed_coverage_features: displayed_coverage_features,
            offer_options_attributes: offer_options_attributes_without_plan,
            note_to_customer: note_to_customer,
            documents_attributes: documents_attributes
          }
        end

        run_test! do |_response|
          translation = I18n.t("dry_validation.errors.rules.plan_ident.filled?")
          expect(json_response[:error])
            .to include({ "0" => { "product_attributes" => { "plan_ident" => [translation] } } })
        end
      end

      response "422", "Offer options 'premium_price' is empty" do
        let!(:customer) { create(:customer) }
        let!(:opportunity) { create(:opportunity_with_offer, mandate_id: customer.id) }
        let!(:offer) { opportunity.offer }
        let!(:id) { offer.id }
        let!(:authentication) { login_as(admin, scope: :admin) }

        let!(:offer_options_attributes_without_premium_price) do
          offer_options_attributes.map do |opt_attributes|
            opt_attributes["product_attributes"]["premium_price"] = ""
            opt_attributes
          end
        end

        let!(:body) do
          {
            displayed_coverage_features: displayed_coverage_features,
            offer_options_attributes: offer_options_attributes_without_premium_price,
            note_to_customer: note_to_customer,
            documents_attributes: documents_attributes
          }
        end

        run_test! do |_response|
          translation = I18n.t("dry_validation.errors.rules.premium_price.filled?")
          expect(json_response[:error])
            .to include({ "0" => { "product_attributes" => { "premium_price" => [translation] } } })
        end
      end

      response "422", "Offer options 'premium_price' is not positive" do
        let!(:customer) { create(:customer) }
        let!(:opportunity) { create(:opportunity_with_offer, mandate_id: customer.id) }
        let!(:offer) { opportunity.offer }
        let!(:id) { offer.id }
        let!(:authentication) { login_as(admin, scope: :admin) }

        let!(:offer_options_attributes_without_premium_price) do
          offer_options_attributes.map do |opt_attributes|
            opt_attributes["product_attributes"]["premium_price"] = "-1"
            opt_attributes
          end
        end

        let!(:body) do
          {
            displayed_coverage_features: displayed_coverage_features,
            offer_options_attributes: offer_options_attributes_without_premium_price,
            note_to_customer: note_to_customer,
            documents_attributes: documents_attributes
          }
        end

        run_test! do |_response|
          translation = I18n.t("dry_validation.errors.rules.premium_price.should_be_positive")
          expect(json_response[:error]).to include({ "0" => [translation] })
        end
      end

      response "422", "Offer options 'premium_period' is empty" do
        let!(:customer) { create(:customer) }
        let!(:opportunity) { create(:opportunity_with_offer, mandate_id: customer.id) }
        let!(:offer) { opportunity.offer }
        let!(:id) { offer.id }
        let!(:authentication) { login_as(admin, scope: :admin) }

        let!(:offer_options_attributes_without_premium_period) do
          offer_options_attributes.map do |opt_attributes|
            opt_attributes["product_attributes"]["premium_period"] = ""
            opt_attributes
          end
        end

        let!(:body) do
          {
            displayed_coverage_features: displayed_coverage_features,
            offer_options_attributes: offer_options_attributes_without_premium_period,
            note_to_customer: note_to_customer,
            documents_attributes: documents_attributes
          }
        end

        run_test! do |_response|
          translation = I18n.t("dry_validation.errors.rules.premium_period.filled?")
          expect(json_response[:error])
            .to include({ "0" => { "product_attributes" => { "premium_period" => [translation] } } })
        end
      end

      response "422", "Offer options 'contract_started_at' before current date" do
        let!(:customer) { create(:customer) }
        let!(:opportunity) { create(:opportunity_with_offer, mandate_id: customer.id) }
        let!(:offer) { opportunity.offer }
        let!(:id) { offer.id }
        let!(:authentication) { login_as(admin, scope: :admin) }

        let!(:offer_options_attributes_with_invalid_start_date) do
          offer_options_attributes.map do |opt_attributes|
            opt_attributes["product_attributes"]["contract_started_at"] = (Time.zone.today - 1.day).strftime("%Y-%m-%d")
            opt_attributes
          end
        end

        let!(:body) do
          {
            displayed_coverage_features: displayed_coverage_features,
            offer_options_attributes: offer_options_attributes_with_invalid_start_date,
            note_to_customer: note_to_customer,
            documents_attributes: documents_attributes
          }
        end

        run_test! do |_response|
          translation = I18n.t("dry_validation.errors.rules.contract_started_at.before_current_date")
          expect(json_response[:error])
            .to include({ "0" => [translation] })
        end
      end

      response "422", "Offer options 'contract_ended_at' before 'contract_started_at'" do
        let!(:customer) { create(:customer) }
        let!(:opportunity) { create(:opportunity_with_offer, mandate_id: customer.id) }
        let!(:offer) { opportunity.offer }
        let!(:id) { offer.id }
        let!(:authentication) { login_as(admin, scope: :admin) }

        let!(:offer_options_attributes_with_invalid_end_date) do
          offer_options_attributes.map do |opt_attributes|
            opt_attributes["product_attributes"]["contract_ended_at"] = (Time.zone.today - 1.day).strftime("%Y-%m-%d")
            opt_attributes
          end
        end

        let!(:body) do
          {
            displayed_coverage_features: displayed_coverage_features,
            offer_options_attributes: offer_options_attributes_with_invalid_end_date,
            note_to_customer: note_to_customer,
            documents_attributes: documents_attributes
          }
        end

        run_test! do |_response|
          translation = I18n.t("dry_validation.errors.rules.contract_ended_at.before_contract_start")
          expect(json_response[:error])
            .to include({ "0" => [translation] })
        end
      end

      response "422", "Offer options 'option_type' is empty" do
        let!(:customer) { create(:customer) }
        let!(:opportunity) { create(:opportunity_with_offer, mandate_id: customer.id) }
        let!(:offer) { opportunity.offer }
        let!(:id) { offer.id }
        let!(:authentication) { login_as(admin, scope: :admin) }

        let!(:offer_options_attributes_without_option_type) do
          offer_options_attributes.map do |opt_attributes|
            opt_attributes["option_type"] = ""
            opt_attributes
          end
        end

        let!(:body) do
          {
            displayed_coverage_features: displayed_coverage_features,
            offer_options_attributes: offer_options_attributes_without_option_type,
            note_to_customer: note_to_customer,
            documents_attributes: documents_attributes
          }
        end

        run_test! do |_response|
          translation = I18n.t("dry_validation.errors.rules.option_type.filled?")
          expect(json_response[:error])
            .to include({ "0" => { "option_type" => [translation] } })
        end
      end

      response "422", "Offer options 'plan_ident' is empty" do
        let!(:customer) { create(:customer) }
        let!(:opportunity) { create(:opportunity_with_offer, mandate_id: customer.id) }
        let!(:offer) { opportunity.offer }
        let!(:id) { offer.id }
        let!(:authentication) { login_as(admin, scope: :admin) }

        let!(:offer_options_attributes_without_plan) do
          offer_options_attributes.map do |opt_attributes|
            opt_attributes["product_attributes"]["plan_ident"] = ""
            opt_attributes
          end
        end

        let!(:body) do
          {
            displayed_coverage_features: displayed_coverage_features,
            offer_options_attributes: offer_options_attributes_without_plan,
            note_to_customer: note_to_customer,
            documents_attributes: documents_attributes
          }
        end

        run_test! do |_response|
          translation = I18n.t("dry_validation.errors.rules.plan_ident.filled?")
          expect(json_response[:error])
            .to include({ "0" => { "product_attributes" => { "plan_ident" => [translation] } } })
        end
      end

      response "422", "Offer options 'premium_price' is empty" do
        let!(:customer) { create(:customer) }
        let!(:opportunity) { create(:opportunity_with_offer, mandate_id: customer.id) }
        let!(:offer) { opportunity.offer }
        let!(:id) { offer.id }
        let!(:authentication) { login_as(admin, scope: :admin) }

        let!(:offer_options_attributes_without_premium_price) do
          offer_options_attributes.map do |opt_attributes|
            opt_attributes["product_attributes"]["premium_price"] = ""
            opt_attributes
          end
        end

        let!(:body) do
          {
            displayed_coverage_features: displayed_coverage_features,
            offer_options_attributes: offer_options_attributes_without_premium_price,
            note_to_customer: note_to_customer,
            documents_attributes: documents_attributes
          }
        end

        run_test! do |_response|
          translation = I18n.t("dry_validation.errors.rules.premium_price.filled?")
          expect(json_response[:error])
            .to include({ "0" => { "product_attributes" => { "premium_price" => [translation] } } })
        end
      end

      response "422", "Offer options 'premium_price' is not positive" do
        let!(:customer) { create(:customer) }
        let!(:opportunity) { create(:opportunity_with_offer, mandate_id: customer.id) }
        let!(:offer) { opportunity.offer }
        let!(:id) { offer.id }
        let!(:authentication) { login_as(admin, scope: :admin) }

        let!(:offer_options_attributes_without_premium_price) do
          offer_options_attributes.map do |opt_attributes|
            opt_attributes["product_attributes"]["premium_price"] = "-1"
            opt_attributes
          end
        end

        let!(:body) do
          {
            displayed_coverage_features: displayed_coverage_features,
            offer_options_attributes: offer_options_attributes_without_premium_price,
            note_to_customer: note_to_customer,
            documents_attributes: documents_attributes
          }
        end

        run_test! do |_response|
          translation = I18n.t("dry_validation.errors.rules.premium_price.should_be_positive")
          expect(json_response[:error]).to include({ "0" => [translation] })
        end
      end

      response "422", "Offer options 'premium_period' is empty" do
        let!(:customer) { create(:customer) }
        let!(:opportunity) { create(:opportunity_with_offer, mandate_id: customer.id) }
        let!(:offer) { opportunity.offer }
        let!(:id) { offer.id }
        let!(:authentication) { login_as(admin, scope: :admin) }

        let!(:offer_options_attributes_without_premium_period) do
          offer_options_attributes.map do |opt_attributes|
            opt_attributes["product_attributes"]["premium_period"] = ""
            opt_attributes
          end
        end

        let!(:body) do
          {
            displayed_coverage_features: displayed_coverage_features,
            offer_options_attributes: offer_options_attributes_without_premium_period,
            note_to_customer: note_to_customer,
            documents_attributes: documents_attributes
          }
        end

        run_test! do |_response|
          translation = I18n.t("dry_validation.errors.rules.premium_period.filled?")
          expect(json_response[:error])
            .to include({ "0" => { "product_attributes" => { "premium_period" => [translation] } } })
        end
      end

      response "422", "Offer options 'contract_started_at' before current date" do
        let!(:customer) { create(:customer) }
        let!(:opportunity) { create(:opportunity_with_offer, mandate_id: customer.id) }
        let!(:offer) { opportunity.offer }
        let!(:id) { offer.id }
        let!(:authentication) { login_as(admin, scope: :admin) }

        let!(:offer_options_attributes_with_invalid_start_date) do
          offer_options_attributes.map do |opt_attributes|
            opt_attributes["product_attributes"]["contract_started_at"] = (Time.zone.today - 1.day).strftime("%Y-%m-%d")
            opt_attributes
          end
        end

        let!(:body) do
          {
            displayed_coverage_features: displayed_coverage_features,
            offer_options_attributes: offer_options_attributes_with_invalid_start_date,
            note_to_customer: note_to_customer,
            documents_attributes: documents_attributes
          }
        end

        run_test! do |_response|
          translation = I18n.t("dry_validation.errors.rules.contract_started_at.before_current_date")
          expect(json_response[:error])
            .to include({ "0" => [translation] })
        end
      end

      response "422", "Offer options 'contract_ended_at' before 'contract_started_at'" do
        let!(:customer) { create(:customer) }
        let!(:opportunity) { create(:opportunity_with_offer, mandate_id: customer.id) }
        let!(:offer) { opportunity.offer }
        let!(:id) { offer.id }
        let!(:authentication) { login_as(admin, scope: :admin) }

        let!(:offer_options_attributes_with_invalid_end_date) do
          offer_options_attributes.map do |opt_attributes|
            opt_attributes["product_attributes"]["contract_ended_at"] = (Time.zone.today - 1.day).strftime("%Y-%m-%d")
            opt_attributes
          end
        end

        let!(:body) do
          {
            displayed_coverage_features: displayed_coverage_features,
            offer_options_attributes: offer_options_attributes_with_invalid_end_date,
            note_to_customer: note_to_customer,
            documents_attributes: documents_attributes
          }
        end

        run_test! do |_response|
          translation = I18n.t("dry_validation.errors.rules.contract_ended_at.before_contract_start")
          expect(json_response[:error])
            .to include({ "0" => [translation] })
        end
      end

      response "200", "for valid offer id and offer parameters" do
        let!(:customer) { create(:customer) }
        let!(:opportunity) { create(:opportunity_with_offer, mandate_id: customer.id) }
        let!(:offer) { opportunity.offer }
        let!(:id) { offer.id }
        let!(:authentication) { login_as(admin, scope: :admin) }

        let!(:options_attributes) do
          offer_options_attributes.tap do |attrs|
            attrs[0] = attrs[0].merge(id: offer.offer_options.find(&:recommended).id)
          end
        end

        let!(:body) do
          {
            displayed_coverage_features: displayed_coverage_features,
            offer_options_attributes: offer_options_attributes,
            note_to_customer: note_to_customer,
            documents_attributes: documents_attributes
          }
        end

        run_test! do |_response|
          response_data = json_response[:data][:attributes]
          updated_offer = offer.reload
          comment = response_data["note_to_customer"]

          expect(json_response["data"]["id"]).to eq(updated_offer.id)
          expect(response_data["customer_id"]).to eq(updated_offer.mandate_id)
          expect(response_data["state"]).to eq(updated_offer.state)
          expect(response_data["offered_on"].to_datetime.utc.to_s).to eq(updated_offer.offered_on.utc.to_s)
          expect(response_data["valid_until"].to_datetime.utc.to_s).to eq(updated_offer.valid_until.utc.to_s)
          expect(response_data["displayed_coverage_features"]).to eq(updated_offer.displayed_coverage_features)
          expect(response_data["active_offer_selected"]).to eq(updated_offer.active_offer_selected)
          expect(response_data["info"]).to eq(updated_offer.info)
          expect(response_data["offer_rule_id"]).to eq(updated_offer.offer_rule_id)
          offer_option = response_data["offer_options"].first

          expect(offer_option.keys).to match(
            %w[offer_option_id premium_price_cents premium_price_currency premium_period contract_id contract_start
               contract_end plan_ident coverages documents option_type]
          )

          expect(comment).to eq(updated_offer.note_to_customer)
          expect(comment).to include("\t")
          expect(comment).to include("\n")
          expect(comment).to include("<h2>")
          expect(comment).to include("<p>")
        end
      end
    end
  end
end
