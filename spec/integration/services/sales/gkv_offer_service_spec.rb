# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sales::GkvOfferService, integration: true do
  let(:subject) { Sales::GkvOfferService.new }
  let(:admin) { create(:admin, email: RoboAdvisor::ADVICE_ADMIN_EMAILS.first) }

  let(:mandate) { create(:mandate, :created, user: create(:user)) }

  let(:whitelist_company) do
    create(
      :gkv_company,
      gkv_whitelisted: true,
      national_health_insurance_premium_percentage: 1.1
    )
  end

  before do

    # Really important to set this, since otherwise business events will not be created.
    # The consequence would be, that the automation cannot find the mandate candidates.
    BusinessEvent.audit_person = admin

    category = create(:category_gkv)

    # We need at least three coverages we can show.
    coverage_features = category.coverage_features.select { |cf| cf.value_type == "Text" }
    coverages = coverage_features.map { |cf| [cf.identifier, ValueTypes::Boolean::TRUE] }.to_h
    expect(coverages.count >= 3).to be_truthy

    # We need a gkv plan for the product creation.
    Plan.create(
      name:      "Some GKV",
      company:   whitelist_company,
      category:  category,
      coverages: coverages
    )
  end

  it "automates the advice and offer sending", :business_events do
    whitelist_inquiry = create(:inquiry, company: whitelist_company, mandate: mandate)
    expect(mandate.inquiries).not_to be_empty
    expect(whitelist_inquiry.products.count).to eq(0)

    schedule_double = n_double("schedule_double")
    expect(CreateGkvProductJob).to receive(:set).with(Hash).and_return(schedule_double)
    expect(schedule_double).to receive(:perform_later).with(mandate_id: mandate.id)

    # The automation process starts here. ##########################################################
    Domain::AcceptCustomers::Processes.accept_customer_process(mandate)

    Timecop.freeze(Time.zone.now)

    # The product creation is scheduled in two days in the morning. ################################
    time_to_travel = Time.zone.today.beginning_of_day.advance(days: 2, hours: 8)
    Timecop.travel(time_to_travel)
    expect(subject.mandates_accepted_older_than_24hago).to include(mandate.id)

    # The job execution needs to be pretended, since we mocked it earlier.
    Domain::Products::GkvProductCreator.new(mandate).create_gkv_product

    whitelist_inquiry.reload
    expect(whitelist_inquiry.products.count).to eq(1)

    product = whitelist_inquiry.products.last
    advice_rule = Sales::Rules::GkvAdviceRule.new(product: product)
    offer_rule = Sales::Rules::OptimizeGkvRuleTkHkk.new(old_product: product)

    expect(advice_rule).not_to be_applicable
    expect(offer_rule).not_to be_applicable

    # The gkv automation sends out the advice one hour after product creation. #####################
    Timecop.travel(1.hour)

    expect(subject.select_new_gkv_to_advice).to include(product)
    expect(advice_rule).to be_applicable

    # STEP 1: send advice ##########################################################################
    sent_advices = subject.task_send_gkv_advices
    ################################################################################################

    expect(subject.select_new_gkv_to_advice).not_to include(product)
    expect(sent_advices).to eq(1)
    expect(product.advices.count).to eq(1)

    expect(offer_rule).to be_applicable

    expect(subject.select_opportunities_to_remind.map(&:old_product)).not_to include(product)

    # Send even when advice is acknowledged.
    product.advices.update_all(acknowledged: true)
    expect(offer_rule).to be_applicable

    # The offer sending is delayed by some more time. ##############################################
    Timecop.travel(2.hours)

    expect(subject.select_opportunities_to_remind.map(&:old_product)).to include(product)

    # STEP 2: send offers ##########################################################################
    expect(subject.task_send_gkv_offers).to eq(1)
    ################################################################################################

    opportunity = Opportunity.find_by(mandate: mandate, category: Category.gkv)
    expect(opportunity).to be_present
    expect(opportunity).to be_offer_phase

    offer = opportunity.offer
    expect(offer).to be_present
    expect(offer).to be_active

    expect(subject.select_opportunities_to_remind.map(&:old_product)).not_to include(product)

    Timecop.return
  end
end
