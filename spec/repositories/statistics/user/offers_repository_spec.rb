# frozen_string_literal: true

require "rails_helper"

RSpec.describe Statistics::User::OffersRepository, :integration do
  subject { described_class.new(mandate: mandate) }

  let(:user) do
    create(
      :user,
      last_sign_in_at: last_sign_in_at,
      current_sign_in_at: current_sign_in_at
    )
  end
  let(:mandate) { create(:mandate, user: user) }

  let(:now) { Time.zone.parse("2010-01-03 10:00:00") }
  let(:yesterday) { Time.zone.parse("2010-01-02 23:59:59") }
  let(:last_sign_in_at) { Time.zone.parse("2010-01-03 00:00:00") }
  let(:current_sign_in_at) { Time.zone.parse("2010-01-03 00:30:00") }
  let(:after_sign_in) { Time.zone.parse("2010-01-03 01:00:00") }

  let(:offer) do
    create(
      :offer,
      mandate: mandate,
      created_at: offer_created_at,
      state: offer_state
    )
  end

  def create_business_event(entity, created_at, new_state)
    create(
      :business_event,
      entity: entity,
      created_at: created_at,
      metadata: {
        state: {
          new: new_state
        }
      }
    )
  end

  before { Timecop.freeze(now) }

  after { Timecop.return }

  describe "#created_since" do
    let(:offer_state) { "active" }

    context "with offer created in :last_login range" do
      let(:offer_created_at) { after_sign_in }

      it "returns the offer" do
        expect(subject.created_since(period: :last_login)).to eq([offer])
      end
    end

    context "with offer created before :last_login range" do
      let(:offer_created_at) { before_sign_in }

      it "returns no offer" do
        expect(subject.created_since(period: :last_login)).to eq([])
      end
    end
  end

  describe "#requested" do
    context "with offer requested in :today range" do
      let(:offer_created_at) { after_sign_in }
      let(:offer_state) { "in_creation" }

      let!(:business_event) { create_business_event(offer, after_sign_in, "in_creation") }

      it "returns the offer" do
        expect(subject.requested(period: :today)).to eq([offer])
      end
    end

    context "with offer requested before :today range" do
      let(:offer_created_at) { yesterday }
      let(:offer_state) { "in_creation" }

      let!(:business_event) { create_business_event(offer, yesterday, "in_creation") }

      it "returns no offer" do
        expect(subject.requested(period: :today)).to eq([])
      end
    end
  end

  describe "#accepted" do
    context "with offer accepted in :today range" do
      let(:offer_created_at) { after_sign_in }
      let(:offer_state) { "accepted" }

      let!(:business_event) { create_business_event(offer, after_sign_in, "accepted") }

      it "returns the offer" do
        expect(subject.accepted(period: :today)).to eq([offer])
      end
    end

    context "with offer accepted before :today range" do
      let(:offer_created_at) { yesterday }
      let(:offer_state) { "accepted" }

      let!(:business_event) { create_business_event(offer, yesterday, "accepted") }

      it "returns no offer" do
        expect(subject.accepted(period: :last_login)).to eq([])
      end
    end
  end
end
