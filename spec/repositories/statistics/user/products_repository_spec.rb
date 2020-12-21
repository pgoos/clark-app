# frozen_string_literal: true

require "rails_helper"

RSpec.describe Statistics::User::ProductsRepository, :integration do
  subject { described_class.new(mandate: mandate) }

  def create_business_event(product, created_at, new_state)
    create(
      :business_event,
      entity: product,
      created_at: created_at,
      metadata: {
        state: {
          new: new_state
        }
      }
    )
  end

  def create_product(state)
    create(
      :product,
      mandate: mandate,
      state: state,
      inquiry: create(:inquiry)
    )
  end

  let(:user) do
    create(
      :user,
      last_sign_in_at: last_sign_in_at
    )
  end
  let(:mandate) { create(:mandate, user: user) }

  let(:now) { Time.zone.parse("2010-01-03 10:00:00") }
  let(:last_sign_in_at) { Time.zone.parse("2010-01-03 00:00:00") }
  let(:after_sign_in) { Time.zone.parse("2010-01-03 01:00:00") }
  let(:before_sign_in) { Time.zone.parse("2010-01-02 23:00:00") }

  let(:details_available) { "details_available" }
  let(:under_management) { "under_management" }

  let!(:product1) { create_product(details_available) }
  let!(:product2) { create_product(under_management) }

  before { Timecop.freeze(now) }

  after { Timecop.return }

  context "with two products in used states" do
    let(:states) { [details_available, under_management] }

    context "when both products created in :last_login range" do
      let!(:business_event1) { create_business_event(product1, after_sign_in, details_available) }
      let!(:business_event2) { create_business_event(product2, after_sign_in, under_management) }

      it "returns both" do
        expect(subject.entered_into_status(period: :last_login, states: states)).to eq([product1, product2])
      end
    end

    context "when one of the products is before :last_login range" do
      let!(:business_event1) { create_business_event(product1, before_sign_in, details_available) }
      let!(:business_event2) { create_business_event(product2, after_sign_in, under_management) }

      it "returns the second product" do
        expect(subject.entered_into_status(period: :last_login, states: states)).to eq([product2])
      end
    end
  end

  context "with two products: one in used state, another in unused state" do
    let(:states) { [under_management] }
    let!(:business_event1) { create_business_event(product1, after_sign_in, details_available) }
    let!(:business_event2) { create_business_event(product2, after_sign_in, under_management) }

    it "returns the second product" do
      expect(subject.entered_into_status(period: :last_login, states: states)).to eq([product2])
    end
  end
end
