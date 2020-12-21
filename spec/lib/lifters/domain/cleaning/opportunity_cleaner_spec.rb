# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Cleaning::OpportunityCleaner do
  let(:mandate) { create(:mandate, :accepted) }
  let(:category_x) { create(:category) }
  let(:category_y) { create(:category) }
  let(:category_z) { create(:category) }
  let(:today) { Time.zone.today }
  let(:positive_integer) { (100 * rand).floor + 1 }
  let(:on_threshold) { today + positive_integer }
  let(:over_threshold) { on_threshold + 1 }

  before do
    Timecop.freeze(today)
    create(:admin) # needed for business events
  end

  after { Timecop.return }

  def new_opportunity(opportunity_state, offer_state, category)
    opportunity = create(
      :opportunity,
      mandate:  mandate,
      state:    opportunity_state,
      category: category,
      offer:    create(
        :offer,
        mandate: mandate,
        state:   offer_state
      )
    )
    BusinessEvent.create!(
      audited_mandate: mandate,
      person:          Admin.last,
      entity:          opportunity.offer,
      action:          "update",
      metadata:        {
        "state" => {
          "new" => offer_state
        }
      }
    )
    opportunity
  end

  def assert_states(opportunity, opportunity_state, offer_state=nil)
    opportunity.reload
    expect(opportunity.state).to eq(opportunity_state)
    expect(opportunity.offer.state).to eq(offer_state) if offer_state.present?
  end

  def assert_cleaned(opportunity)
    assert_states(opportunity, "lost", "canceled")
  end

  context "offer states" do
    it "should choose opportunities with active offers" do
      opportunity = new_opportunity("offer_phase", "active", category_x)
      Timecop.travel(over_threshold)

      subject.clean(category_x.ident, positive_integer)

      assert_cleaned(opportunity)
    end

    Offer.state_machine.states.keys.except(:active).map(&:to_s).each do |offer_state|
      it "should not choose opportunities with offers in the state #{offer_state}" do
        opportunity_state = "offer_phase"
        opportunity       = new_opportunity(opportunity_state, offer_state, category_x)
        Timecop.travel(over_threshold)

        subject.clean(category_x.ident, positive_integer)

        assert_states(opportunity, opportunity_state, offer_state)
      end
    end

    it "should clean the opportunity, if no offer attached (sent via mail)" do
      opportunity = create(:opportunity, state: "offer_phase", category: category_x)
      Timecop.travel(over_threshold)

      subject.clean(category_x.ident, positive_integer)

      opportunity.reload
      expect(opportunity).to be_lost
    end

    it "should leave the opportunity, if no offer attached (sent via mail) but too young" do
      opportunity_state = "offer_phase"
      opportunity = create(:opportunity, state: opportunity_state, category: category_x)
      Timecop.travel(on_threshold)

      subject.clean(category_x.ident, positive_integer)

      opportunity.reload
      expect(opportunity.state).to eq(opportunity_state)
    end
  end

  context "opportunity states" do
    %w[created initiation_phase offer_phase].each do |state|
      it "should select opportunities of the state #{state}" do
        opportunity = new_opportunity(state, "active", category_x)
        Timecop.travel(over_threshold)

        subject.clean(category_x.ident, positive_integer)

        assert_cleaned(opportunity)
      end
    end

    %w[lost completed].each do |opportunity_state|
      it "should not choose opportunities of the state #{opportunity_state}" do
        opportunity = new_opportunity(opportunity_state, "active", category_x)
        Timecop.travel(over_threshold)

        subject.clean(category_x.ident, positive_integer)

        assert_states(opportunity, opportunity_state)
      end
    end
  end

  context "day variations" do
    it "clean up return the empty set, if all opportunities are younger than n days ago" do
      opportunity_state = "offer_phase"
      offer_state       = "active"
      opportunity = new_opportunity(opportunity_state, offer_state, category_x)
      Timecop.travel(on_threshold)

      subject.clean(category_x.ident, positive_integer)

      assert_states(opportunity, opportunity_state, offer_state)
    end

    it "clean up return k opportunities, if k opportunities are older than n days ago" do
      opportunity_state = "offer_phase"
      offer_state       = "active"

      opportunity1 = new_opportunity(opportunity_state, offer_state, category_x)
      opportunity2 = new_opportunity(opportunity_state, offer_state, category_x)
      Timecop.travel(over_threshold)

      subject.clean(category_x.ident, positive_integer)

      assert_cleaned(opportunity1)
      assert_cleaned(opportunity2)
    end
  end

  context "categories" do
    it "clean up no opportunity of category y, if old enough but category x is requested" do
      opportunity_state = "offer_phase"
      offer_state       = "active"
      opportunity = new_opportunity(opportunity_state, offer_state, category_y)
      Timecop.travel(over_threshold)

      subject.clean(category_x.ident, positive_integer)

      assert_states(opportunity, opportunity_state, offer_state)
    end
  end
end
