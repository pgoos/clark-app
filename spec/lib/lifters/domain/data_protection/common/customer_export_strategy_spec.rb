# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::DataProtection::Common::CustomerExportStrategy do
  let(:admin) { create(:admin) }
  let(:mandate) { create(:mandate) }
  let!(:document_type) { create(:document_type, key: "export_data") }

  describe ".run" do
    it "attaches document to mandate" do
      expect(mandate.documents.count).to eq 0
      service = described_class.new(admin, mandate)
      service.run
      expect(mandate.documents.count).to eq 1
      document = mandate.documents.first
      expect(document.document_type.key).to eq "export_data"
      expect(document.content_type).to eq "json"
    end

    it "sends email with link to mandate" do
      receiver = double("Receiver")
      allow(receiver).to receive(:deliver_now)

      expect(DataProtectionMailer).to(
        receive(:export_notification)
        .with(admin, mandate)
        .and_return(receiver)
      )

      described_class.new(admin, mandate).run
    end

    it "exports right mandate keys to json file" do
      service = described_class.new(admin, mandate)
      service.run
      data = service.data

      expect(data["mandate"].keys).to eq(%w[
                                           first_name
                                           last_name
                                           birthdate
                                           gender
                                           tos_accepted_at
                                           confirmed_at
                                           newsletter
                                           company_name
                                           encrypted_iban
                                           encrypted_iban_iv
                                           contactable_at
                                           satisfaction
                                           loyalty
                                           accessible_by
                                           health_and_care_insurance
                                           church_membership
                                           health_consent_accepted_at
                                           customer_state
                                           iban
                                           primary_phone_number
                                           addresses
                                           lead
                                           user
                                           document
                                           signatures
                                           products
                                           offers
                                           comments
                                           profile_data
                                           phones
                                           voucher
                                           follow_ups
                                           appointments
                                           loyalty_bookings
                                           retirement_cockpit
                                           retirement_products
                                           insurance_comparisons
                                           recommendations
                                           opportunities
                                           interactions
                                           inquiries
                                           questionnaire_responses
                                           business_events
                                           feed_logs
                                         ])
    end

    it "exports right keys for address" do
      create(:address, mandate: mandate)
      service = described_class.new(admin, mandate)
      service.run
      data = service.data
      expect(data["mandate"]["addresses"].first.keys).to eq(%w[
                                                              street
                                                              house_number
                                                              zipcode
                                                              city
                                                              country_code
                                                              addition_to_address
                                                              active
                                                              accepted
                                                              apartment_size
                                                              active_at
                                                              insurers_notified
                                                            ])
    end

    it "exports right keys for lead" do
      create(:lead, mandate: mandate)
      service = described_class.new(admin, mandate)
      service.run
      data = service.data
      expect(data["mandate"]["lead"].keys).to eq(%w[
                                                   email
                                                   subscriber
                                                   terms
                                                   campaign
                                                   registered_with_ip
                                                   infos
                                                   confirmed_at
                                                   source_data
                                                   state
                                                   inviter_code
                                                   restore_session_token
                                                 ])
    end

    it "exports right keys for user" do
      create(:user, mandate: mandate)
      service = described_class.new(admin, mandate)
      service.run
      data = service.data
      expect(data["mandate"]["user"].keys).to eq(%w[
                                                   email
                                                   confirmed_at
                                                   confirmation_sent_at
                                                   unconfirmed_email
                                                   state
                                                   info
                                                   referral_code
                                                   inviter_id
                                                   inviter_code
                                                   subscriber
                                                   source_data
                                                 ])
    end

    it "exports right keys for document" do
      document = create(:document)
      mandate.document = document
      service = described_class.new(admin, mandate)
      service.run
      data = service.data
      expect(data["mandate"]["document"].keys).to eq(%w[
                                                       asset
                                                       content_type
                                                       size
                                                       documentable_type
                                                       metadata
                                                     ])
    end

    it "exports right keys for signatures" do
      create(:signature, signable: mandate)
      service = described_class.new(admin, mandate)
      service.run
      data = service.data
      expect(data["mandate"]["signatures"].first.keys).to eq(%w[
                                                               signable_type
                                                               asset
                                                             ])
    end

    it "exports right kyes for products" do
      create(:product, mandate: mandate, retirement_product: build(:retirement_product))
      service = described_class.new(admin, mandate)
      service.run
      data = service.data

      expect(data["mandate"]["products"].first.keys).to eq(%w[
                                                             state
                                                             number
                                                             premium_price_cents
                                                             premium_price_currency
                                                             premium_period
                                                             contract_started_at
                                                             contract_ended_at
                                                             portfolio_commission_price_cents
                                                             portfolio_commission_price_currency
                                                             portfolio_commission_period
                                                             acquisition_commission_price_cents
                                                             acquisition_commission_price_currency
                                                             acquisition_commission_period
                                                             acquisition_commission_payouts_count
                                                             acquisition_commission_conditions
                                                             notes
                                                             premium_state
                                                             coverages
                                                             turnover_possible
                                                             insurance_holder
                                                             rating
                                                             renewal_period
                                                             annual_maturity
                                                             managed_by_pool
                                                             means_of_payment
                                                             takeover_requested_at
                                                             cancellation_reason
                                                             takeover_possible
                                                             sold_by
                                                             new_contract_sales_channel
                                                             deduction_reserve_sales
                                                             deduction_fidelity_sales
                                                             latest_cancellation_date
                                                           ])
    end

    it "exports right kyes for offers" do
      create(:offer, mandate: mandate)
      service = described_class.new(admin, mandate)
      service.run
      data = service.data

      expect(data["mandate"]["offers"].first.keys).to eq(%w[
                                                           state
                                                           offered_on
                                                           valid_until
                                                           note_to_customer
                                                           displayed_coverage_features
                                                           active_offer_selected
                                                           info
                                                         ])
    end

    it "exports right kyes for comments" do
      create(:comment, commentable: mandate, admin: admin)
      service = described_class.new(admin, mandate)
      service.run
      data = service.data

      expect(data["mandate"]["comments"].first.keys).to eq(%w[message])
    end

    it "exports right kyes for profile_data" do
      create(:profile_datum, mandate: mandate)
      service = described_class.new(admin, mandate)
      service.run
      data = service.data

      expect(data["mandate"]["profile_data"].first.keys).to eq(%w[
                                                                 property_identifier
                                                                 value
                                                                 source
                                                               ])
    end

    it "exports right kyes for phones" do
      create(:phone, mandate: mandate)
      service = described_class.new(admin, mandate)
      service.run
      data = service.data
      expect(data["mandate"]["phones"].first.keys).to eq(%w[
                                                           number
                                                           verification_token
                                                           token_created_at
                                                           verified_at
                                                           primary
                                                         ])
    end

    it "exports right kyes for voucher" do
      create(:voucher, mandates: [mandate])
      service = described_class.new(admin, mandate)
      service.run
      data = service.data
      expect(data["mandate"]["voucher"].keys).to eq(%w[
                                                      name
                                                      code
                                                      amount
                                                      valid_from
                                                      valid_until
                                                      metadata
                                                    ])
    end

    it "exports right kyes for follow_ups" do
      mandate.follow_ups = [create(:follow_up)]
      service = described_class.new(admin, mandate)
      service.run
      data = service.data
      expect(data["mandate"]["follow_ups"].first.keys).to eq(%w[
                                                               item_type
                                                               due_date
                                                               comment
                                                               acknowledged
                                                               interaction_type
                                                             ])
    end

    it "exports right kyes for appointments" do
      create(:appointment, mandate: mandate)
      service = described_class.new(admin, mandate)
      service.run
      data = service.data
      expect(data["mandate"]["appointments"].first.keys).to eq(%w[
                                                                 state
                                                                 starts
                                                                 ends
                                                                 call_type
                                                                 appointable_type
                                                                 method_of_contact
                                                               ])
    end

    it "exports right kyes for loyalty_bookings" do
      create(:loyalty_booking, mandate: mandate)
      service = described_class.new(admin, mandate)
      service.run
      data = service.data
      expect(data["mandate"]["loyalty_bookings"].first.keys).to eq(%w[bookable_type kind amount details])
    end

    it "exports right kyes for retirement_cockpit" do
      create(:retirement_cockpit, mandate: mandate)
      service = described_class.new(admin, mandate)
      service.run
      data = service.data
      expect(data["mandate"]["retirement_cockpit"].keys).to eq(%w[
                                                                 state
                                                                 desired_income_cents
                                                                 desired_income_currency
                                                               ])
    end

    it "exports right kyes for retirement_products" do
      create(:product, mandate: mandate, retirement_product: build(:retirement_product))
      service = described_class.new(admin, mandate)
      service.run
      data = service.data
      keys = data["mandate"]["retirement_products"].first.keys
      expect(keys).to eq(%w[
                           category
                           document_date
                           retirement_date
                           guaranteed_pension_continueed_payment_cents
                           guaranteed_pension_continueed_payment_currency
                           guaranteed_pension_continueed_payment_monthly_currency
                           guaranteed_pension_continueed_payment_payment_type
                           surplus_retirement_income_cents
                           surplus_retirement_income_currency
                           surplus_retirement_income_monthly_currency
                           surplus_retirement_income_payment_type
                           retirement_three_percent_growth_cents
                           retirement_three_percent_growth_currency
                           retirement_three_percent_growth_monthly_currency
                           retirement_three_percent_growth_payment_type
                           retirement_factor_cents
                           retirement_factor_currency
                           retirement_factor_monthly_currency
                           retirement_factor_payment_type
                           fund_capital_three_percent_growth_cents
                           fund_capital_three_percent_growth_currency
                           guaranteed_capital_cents
                           guaranteed_capital_currency
                           equity_today_cents
                           equity_today_currency
                           possible_capital_including_surplus_cents
                           possible_capital_including_surplus_currency
                           pension_capital_today_cents
                           pension_capital_today_currency
                           pension_capital_three_percent_cents
                           pension_capital_three_percent_currency
                           type
                           state
                           forecast
                           metadata
                         ])
    end

    it "exports right kyes for insurance_comparisons" do
      create(:insurance_comparison, mandate: mandate)
      service = described_class.new(admin, mandate)
      service.run
      data = service.data
      expect(data["mandate"]["insurance_comparisons"].first.keys).to eq(%w[
                                                                          expected_insurance_begin meta
                                                                        ])
    end

    it "exports right kyes for recommendations" do
      create(:recommendation, mandate: mandate)
      service = described_class.new(admin, mandate)
      service.run
      data = service.data
      expect(data["mandate"]["recommendations"].first.keys).to eq(%w[level is_mandatory dismissed])
    end

    it "exports right kyes for opportunities" do
      create(:opportunity, mandate: mandate)
      service = described_class.new(admin, mandate)
      service.run
      data = service.data
      expect(data["mandate"]["opportunities"].first.keys).to eq(%w[
                                                                  source_type
                                                                  source_description
                                                                  state
                                                                  is_automated
                                                                  metadata
                                                                  followup_situation
                                                                  level
                                                                  sales_campaign_id
                                                                  presales_agent_id
                                                                ])
    end

    it "exports right kyes for interactions" do
      create(:interaction, mandate: mandate)
      service = described_class.new(admin, mandate)
      service.run
      data = service.data
      expect(data["mandate"]["interactions"].first.keys).to eq(%w[
                                                                 type
                                                                 topic_type
                                                                 direction
                                                                 content
                                                                 metadata
                                                                 acknowledged
                                                                 sales_campaign_id
                                                               ])
    end

    it "exports right kyes for inquiries" do
      create(:inquiry, mandate: mandate)
      service = described_class.new(admin, mandate)
      service.run
      data = service.data
      expect(data["mandate"]["inquiries"].first.keys).to eq(%w[
                                                              state remind_at contacted_at gevo company subcompany
                                                            ])
    end

    it "exports right kyes for questionnaire_responses" do
      create(:questionnaire_response, mandate: mandate, answers: [build(:questionnaire_answer)])
      service = described_class.new(admin, mandate)
      service.run
      data = service.data
      expect(data["mandate"]["questionnaire_responses"].first.keys).to eq(%w[answers])
      expect(data["mandate"]["questionnaire_responses"].first["answers"].first.keys).to eq(%w[question_text answer])
    end

    it "exports right keys for business_events" do
      create(:business_event, entity: mandate)
      service = described_class.new(admin, mandate)
      service.run
      data = service.data

      expect(data["mandate"]["business_events"].first.keys).to eq(%w[
                                                                    person_type
                                                                    action
                                                                    metadata
                                                                  ])
    end

    it "exports right keys for feed_logs" do
      create(:feed_log, mandate: mandate)
      service = described_class.new(admin, mandate)
      service.run
      data = service.data
      expect(data["mandate"]["feed_logs"].first.keys).to eq(%w[
                                                              from_server
                                                              text
                                                              event
                                                            ])
    end
  end
end
