# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::MasterData::Categories do
  subject { described_class }

  let!(:regular) { create(:category_phv) }
  let!(:active) { create(:active_category, name: "active-category-name") }
  let!(:available_for_offer_request) {
    create(:active_category, name: "available-for-offer-request-category-name", available_for_offer_request: true)
  }
  let!(:combo) { create(:retirement_equity_combo_category) }

  context "when try to change data" do
    it "should raise error" do
      category = subject.all.last

      expect { category.ident = "another_ident" }.to raise_error RuntimeError, "Can't modify frozen hash"
    end
  end

  describe ".regular" do
    it "returns only regular categories" do
      expect(subject.regular).to include(regular)
      expect(subject.regular).not_to include(combo)
    end
  end

  describe ".all_active" do
    it "returns only active categories" do
      expect(subject.all_active).to include(active)
    end
  end

  describe ".available_for_offer_request" do
    it "returns only active and available_for_offer_request categories" do
      expect(subject.available_for_offer_request).to include(available_for_offer_request)
    end
  end

  describe ".all_active_and_regular" do
    it "returns only active and regular categories" do
      expect(subject.all_active_and_regular).to include(regular)
      expect(regular.active?).to eq true
      expect(subject.all_active_and_regular).not_to include(combo)
    end
  end

  describe ".get_by_ident" do
    it "Returns the correct category" do
      expect(subject.get_by_ident("test-combo-category")).to eq(combo)
      expect(subject.get_by_ident("banana2000")).to be_nil
    end
  end

  context "umbrella and combo categories containing multiple categories" do
    let!(:regular1) { create(:category) }
    let!(:regular2) { create(:category) }
    let!(:combo) { create(:combo_category, included_categories: [regular1, regular2]) }
    let!(:umbrella) { create(:umbrella_category, included_categories: [regular1, regular2]) }

    describe ".get_combo_by_included_category_ids" do
      it "returns the right combo category" do
        expect(subject.get_combo_by_included_category_ids([regular1.id, regular2.id])).to eq(combo)
      end
      it "returns the right combo category even when ordering is different" do
        expect(subject.get_combo_by_included_category_ids([regular2.id, regular1.id])).to eq(combo)
      end
    end

    describe ".get_umbrella_by_included_category_ids" do
      it "returns the right umbrella category" do
        expect(subject.get_umbrella_by_included_category_ids([regular1.id, regular2.id])).to eq(umbrella)
      end
      it "returns the right umbrella category even when ordering is different" do
        expect(subject.get_umbrella_by_included_category_ids([regular2.id, regular1.id])).to eq(umbrella)
      end
    end
  end

  describe ".relevant_ids_for_showing_if_something_is_owned" do
    context "umbrella categories" do
      let!(:umbrella) { create(:umbrella_category, included_categories: [regular]) }

      it "list included categories and itself as relevant" do
        expect(subject.relevant_ids_for_showing_if_something_is_owned(umbrella))
          .to match_array([umbrella.id, regular.id])
      end

      it "list include combos that contain children" do
        combo_containing_regular = create(:combo_category, included_categories: [regular])

        expect(subject.relevant_ids_for_showing_if_something_is_owned(umbrella))
          .to match_array([umbrella.id, regular.id, combo_containing_regular.id])
      end
    end

    context "combo categories" do
      it "list only their own id as relevant" do
        expect(subject.relevant_ids_for_showing_if_something_is_owned(combo))
          .to match_array([combo.id])
      end
    end

    context "regular categories" do
      it "list themselves and combos including them as relevant" do
        combo_containing_regular = create(:combo_category, included_categories: [regular])

        expect(subject.relevant_ids_for_showing_if_something_is_owned(regular))
          .to match_array([combo_containing_regular.id, regular.id])
      end

      it "that are not included in a combo only list themselves as relevant" do
        expect(subject.relevant_ids_for_showing_if_something_is_owned(regular))
          .to match_array([regular.id])
      end
    end
  end

  describe ".combo_categories_that_wrap" do
    let!(:combo) { create(:retirement_equity_combo_category, included_categories: [regular]) }

    it "returns all combo categories that include the given one" do
      expect(subject.combo_categories_that_wrap(regular)).to match_array([combo])
    end
  end

  describe ".retirement" do
    it "includes categories that have retirement ident" do
      category = create :category, ident: Domain::Retirement::CategoryIdents::ALL.last
      expect(subject.retirement).to include category
    end

    it "does not include other than retirement categories" do
      category = create :category
      expect(subject.retirement).not_to include category
    end

    it "does not include combo categoires that have retirement ident included" do
      retirement_category =
        create :category, ident: Domain::Retirement::CategoryIdents::ALL.first
      category = create :combo_category,
                        included_category_ids: [retirement_category.id]
      expect(subject.retirement).not_to include category
    end
  end

  describe ".combo_retirement" do
    it "does not include categories that have retirement ident" do
      category = create :category, ident: Domain::Retirement::CategoryIdents::ALL.last
      expect(subject.combo_retirement).not_to include category
    end

    it "includes combo categoires that have retirement ident included" do
      retirement_category =
        create :category, ident: Domain::Retirement::CategoryIdents::ALL.first
      category = create :combo_category,
                        included_category_ids: [retirement_category.id]
      expect(subject.combo_retirement).to include category
    end
  end
end
