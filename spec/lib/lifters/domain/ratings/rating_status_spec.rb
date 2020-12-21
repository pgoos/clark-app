# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Ratings::RatingStatus do
  subject { described_class.new(events: events) }

  let(:events) { [] }

  it "should define the cycle times" do
    expect(subject.reminder_cycle_times).to be_an(Domain::Ratings::CycleTime)
  end

  describe "#native_modal_enabled?" do
    context "when feature switcher is turned off" do
      before { allow(Features).to receive(:active?).with(Features::NATIVE_RATING_MODAL).and_return false }

      it { expect(subject.native_modal_enabled?).to eq(false) }

      context "when mandate's email is in 'always enabled' list" do
        subject { described_class.new(events: events, mandate: mandate) }

        let(:mandate) { build_stubbed :mandate, user: build_stubbed(:user, email: "test@clark.de") }

        it { expect(subject.native_modal_enabled?).to eq(true) }
      end

      context "when mandate's email is not in 'always enabled' list" do
        subject { described_class.new(events: events, mandate: mandate) }

        let(:mandate) { build_stubbed :mandate, user: build_stubbed(:user, email: "other@clark.de") }

        it { expect(subject.native_modal_enabled?).to eq(false) }
      end
    end

    context "when feature switcher is turned on" do
      before { allow(Features).to receive(:active?).with(Features::NATIVE_RATING_MODAL).and_return true }

      it { expect(subject.native_modal_enabled?).to eq(true) }
    end
  end

  context "when initial state" do
    it "was not shown yet" do
      expect(subject.last_shown).to be_nil
    end

    it "was not rated yet" do
      expect(subject.rated?).to be(false)
    end

    it "does not have a rating value" do
      expect(subject.last_rating).to be_nil
    end

    it "was not dismissed yet" do
      expect(subject.dismissed?).to be(false)
    end

    it "was not triggered yet" do
      expect(subject.triggered?).to be(false)
    end

    it "has no positive ratings yet" do
      expect(subject.positive_ratings_count).to eq(0)
    end
  end

  context "when triggered" do
    let(:t0) { Time.zone.now - 1.second }

    before do
      events << build(:business_event, action: "rating_modal_triggered", created_at: t0)
    end

    it "was not shown yet" do
      expect(subject.last_shown).to be_nil
    end

    it "was not rated yet" do
      expect(subject.rated?).to be(false)
    end

    it "does not have a rating value" do
      expect(subject.last_rating).to be_nil
    end

    it "was not dismissed yet" do
      expect(subject.dismissed?).to be(false)
    end

    it "was not triggered yet" do
      expect(subject.triggered?).to be(true)
    end

    it "has no positive ratings yet" do
      expect(subject.positive_ratings_count).to eq(0)
    end
  end

  context "when simply shown" do
    let(:t0) { Time.zone.now - 2.seconds }
    let(:t1) { Time.zone.now - 1.second }

    before do
      events << build(:business_event, action: "rating_modal_triggered", created_at: t0)
      events << build(:business_event, action: "rating_modal_shown", created_at: t1)
    end

    it "was shown" do
      expect(subject.last_shown).to eq(t1)
    end

    it "was not rated yet" do
      expect(subject.rated?).to be(false)
    end

    it "does not have a rating value" do
      expect(subject.last_rating).to be_nil
    end

    it "was not dismissed yet" do
      expect(subject.dismissed?).to be(false)
    end

    it "was not triggered yet" do
      expect(subject.triggered?).to be(false)
    end

    it "has no positive ratings yet" do
      expect(subject.positive_ratings_count).to eq(0)
    end
  end

  context "when dismissed" do
    let(:t0) { Time.zone.now - 3.seconds }
    let(:t1) { Time.zone.now - 2.seconds }
    let(:t2) { Time.zone.now - 1.second }

    before do
      events << build(:business_event, action: "rating_modal_triggered", created_at: t0)
      events << build(:business_event, action: "rating_modal_shown", created_at: t1)
      events << build(:business_event, action: "rating_modal_dismissed", created_at: t2)
    end

    it "was shown" do
      expect(subject.last_shown).to eq(t1)
    end

    it "was not rated yet" do
      expect(subject.rated?).to be(false)
    end

    it "does not have a rating value" do
      expect(subject.last_rating).to be_nil
    end

    it "was not dismissed yet" do
      expect(subject.dismissed?).to be(true)
    end

    it "was not triggered yet" do
      expect(subject.triggered?).to be(false)
    end

    it "has no positive ratings yet" do
      expect(subject.positive_ratings_count).to eq(0)
    end
  end

  context "when rated positively with a string value" do
    let(:t0) { Time.zone.now - 3.seconds }
    let(:t1) { Time.zone.now - 2.seconds }
    let(:t2) { Time.zone.now - 1.second }
    let(:rating) { {"payload" => {"positive" => "true"}} }

    before do
      events << build(:business_event, action: "rating_modal_triggered", created_at: t0)
      events << build(:business_event, action: "rating_modal_shown", created_at: t1)
      events << build(:business_event, action: "rating_modal_rated", metadata: rating, created_at: t2)
    end

    it "was shown" do
      expect(subject.last_shown).to eq(t1)
    end

    it "was not rated yet" do
      expect(subject.rated?).to be(true)
    end

    it "has a rating value" do
      expect(subject.last_rating).to be_present
      expect(subject.last_rating.positive).to eq(true)
    end

    it "was not dismissed yet" do
      expect(subject.dismissed?).to be(false)
    end

    it "was not triggered yet" do
      expect(subject.triggered?).to be(false)
    end

    it "has one positive rating" do
      expect(subject.positive_ratings_count).to eq(1)
    end
  end

  context "when rated negatively with a bool value" do
    let(:t0) { Time.zone.now - 3.seconds }
    let(:t1) { Time.zone.now - 2.seconds }
    let(:t2) { Time.zone.now - 1.second }
    let(:rating) { {"payload" => {"rating" => false}} }

    before do
      events << build(:business_event, action: "rating_modal_triggered", created_at: t0)
      events << build(:business_event, action: "rating_modal_shown", created_at: t1)
      events << build(:business_event, action: "rating_modal_rated", metadata: rating, created_at: t2)
    end

    it "was shown" do
      expect(subject.last_shown).to eq(t1)
    end

    it "was not rated yet" do
      expect(subject.rated?).to be(true)
    end

    it "does not have a rating value" do
      expect(subject.last_rating).to be_present
      expect(subject.last_rating.positive).to eq(false)
    end

    it "was not dismissed yet" do
      expect(subject.dismissed?).to be(false)
    end

    it "was not triggered yet" do
      expect(subject.triggered?).to be(false)
    end

    it "has no positive ratings yet" do
      expect(subject.positive_ratings_count).to eq(0)
    end
  end

  context "when rated positively once" do
    let(:t0) { Time.zone.now - 4.seconds }
    let(:t1) { Time.zone.now - 3.seconds }
    let(:t2) { Time.zone.now - 2.seconds }
    let(:t3) { Time.zone.now - 1.second }
    let(:rating) { {"payload" => {"positive" => true}} }

    before do
      events << build(:business_event, action: "rating_modal_triggered", created_at: t0)
      events << build(:business_event, action: "rating_modal_shown", created_at: t1)
      events << build(:business_event, action: "rating_modal_rated", metadata: rating, created_at: t2)
    end

    it "was shown" do
      expect(subject.last_shown).to eq(t1)
    end

    it "was not rated yet" do
      expect(subject.rated?).to be(true)
    end

    it "has a rating value" do
      expect(subject.last_rating).to be_present
      expect(subject.last_rating.positive).to eq true
    end

    it "was not dismissed yet" do
      expect(subject.dismissed?).to be(false)
    end

    it "was not triggered yet" do
      expect(subject.triggered?).to be(false)
    end

    it "has one positive rating" do
      expect(subject.positive_ratings_count).to eq(1)
    end

    context "when rated positively once again" do
      it "has two positive ratings" do
        events << build(:business_event, action: "rating_modal_rated", metadata: rating, created_at: t2)
        expect(subject.positive_ratings_count).to eq(2)
      end
    end
  end

  context "when first dismissed and rated later" do
    let(:t0) { Time.zone.now - 6.seconds }
    let(:t1) { Time.zone.now - 5.seconds }
    let(:t2) { Time.zone.now - 4.seconds }
    let(:t3) { Time.zone.now - 3.seconds }
    let(:t4) { Time.zone.now - 2.seconds }
    let(:t5) { Time.zone.now - 1.second }
    let(:rating) { {"payload" => {"positive" => true}} }

    before do
      events << build(:business_event, action: "rating_modal_triggered", created_at: t0)
      events << build(:business_event, action: "rating_modal_shown", created_at: t1)
      events << build(:business_event, action: "rating_modal_dismissed", created_at: t2)
      events << build(:business_event, action: "rating_modal_triggered", created_at: t3)
      events << build(:business_event, action: "rating_modal_shown", created_at: t4)
      events << build(:business_event, action: "rating_modal_rated", metadata: rating, created_at: t5)
    end

    it "was shown" do
      expect(subject.last_shown).to eq(t4)
    end

    it "was not rated yet" do
      expect(subject.rated?).to be(true)
    end

    it "has a rating value" do
      expect(subject.last_rating).to be_present
      expect(subject.last_rating.positive).to eq(true)
    end

    it "was not dismissed yet" do
      expect(subject.dismissed?).to be(false)
    end

    it "was not triggered yet" do
      expect(subject.triggered?).to be(false)
    end

    it "has positive rating" do
      expect(subject.positive_ratings_count).to eq(1)
    end
  end
end
