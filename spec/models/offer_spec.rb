# frozen_string_literal: true
# == Schema Information
#
# Table name: offers
#
#  id                          :integer          not null, primary key
#  mandate_id                  :integer
#  state                       :string           default("in_creation")
#  offered_on                  :datetime
#  valid_until                 :datetime
#  note_to_customer            :text
#  created_at                  :datetime
#  updated_at                  :datetime
#  displayed_coverage_features :string           default([]), is an Array
#  active_offer_selected       :boolean          default(FALSE)
#  info                        :jsonb            not null
#

require "rails_helper"

RSpec.describe Offer, type: :model do
  before do
    @address = create(:address)
    @mandate = create(:mandate, active_address: @address)
    @admin = create(:admin)
    @vertical = create(:vertical)
    @category = create(:category, vertical: @vertical)
    @company = create(:company)
    @plan = create(:plan, vertical: @vertical, category: @category)
    @subcompany = create(:subcompany, verticals: [@vertical], company: @company)
    @opportunity = create(:opportunity, category: @category, admin: @admin, mandate: @mandate)
    @product = create(:product, plan: @plan, mandate: @mandate, category: @category)
  end

  context "concerns" do
    let(:opportunity) do
      create(:opportunity, state: :initiation_phase, mandate: @mandate, category: @category, admin: @admin)
    end
    let(:offer) { create(:offer, opportunity: opportunity, mandate: @mandate) }

    let(:shared_example_model) { offer }
    it_behaves_like "an auditable model"
    it_behaves_like "a documentable"
  end

  it { is_expected.to delegate_method(:category).to(:opportunity) }
  it { is_expected.to delegate_method(:category_ident).to(:opportunity) }
  it { is_expected.to delegate_method(:is_automated=).to(:opportunity).with_arguments(true) }
  it { is_expected.to delegate_method(:admin=).to(:opportunity).with_arguments(build_stubbed(:admin)) }

  it "does not fail to delegate to category, if the opportunity is nil" do
    expect {
      subject.category
    }.not_to raise_exception
  end

  context "offer without opportunity" do
    it "hasn't a valid factory" do
      expect(build(:offer, opportunity: nil)).not_to be_valid
    end
  end

  context "offer with opportunity" do
    let(:offer) { build(:offer, opportunity: @opportunity, mandate: @mandate) }

    it "has a valid factory" do
      expect(build(:offer)).to be_valid
    end

    before do
      # We do not want to send out mails in arbitrary actions ...
      # Those tests that care about the mails will have an expect on the mailer
      %i(offer_available_top_cover_and_price new_product_offer_available offer_available_top_price
         offer_available_top_cover offer_thank_you).each do |message|
        allow(OfferMailer).to receive(message).with(offer)
          .and_return(ActionMailer::Base::NullMail.new)
      end
    end

    describe "ActiveModel validations" do
      context "recommended option validation" do
        it "validates that one option must be recommended" do
          offer.offer_options.build(
            option_type: OfferOption.option_types[:top_price], recommended: false,
            product: @product
          )

          offer.offer_options.build(
            option_type: OfferOption.option_types[:top_cover], recommended: false,
            product: @product
          )

          expect(offer).not_to be_valid
          expect(offer.errors[:offer_options].first)
            .to eq I18n.t("activerecord.errors.models.offer.attributes.offer_options.none")
        end

        it "validates that only one option must be recommended" do
          offer.offer_options.build(
            option_type: OfferOption.option_types[:top_price], recommended: true,
            product: @product
          )

          offer.offer_options.build(
            option_type: OfferOption.option_types[:top_cover], recommended: true,
            product: @product
          )

          expect(offer).not_to be_valid
          expect(offer.errors[:offer_options].first)
            .to eq I18n.t("activerecord.errors.models.offer.attributes.offer_options.more")
        end

        it "validates that exactly only one option must be recommended" do
          offer = build(:offer, mandate: @mandate)

          offer.offer_options.build(
            option_type: OfferOption.option_types[:top_price], recommended: false,
            product: @product
          )

          offer.offer_options.build(
            option_type: OfferOption.option_types[:top_cover], recommended: true,
            product: @product
          )

          expect(offer).to be_valid
        end

        it "exits the validation early when no options are provided" do
          expect(offer.offer_options).to be_empty
          expect(offer).to be_valid
        end

        it "exits the validation early when the only option is the old product" do
          offer.old_product = @product
          offer.save

          expect(offer.offer_options.count).to eq(1)
          expect(offer).to be_valid
        end
      end
    end

    describe "ActiveRecord associations" do
      it { expect(offer).to belong_to(:mandate) }
      it { expect(offer).to belong_to(:offer_rule) }

      it "should be valid, if not associated to an offer rule" do
        offer.offer_rule = nil
        expect(offer).to be_valid
      end

      it { expect(offer).to have_many(:offer_options).dependent(:destroy) }
      it { expect(offer).to have_many(:offered_products) }
      it { expect(offer).to have_many(:follow_ups).dependent(:destroy) }
      it { expect(offer).to have_many(:interactions) }
      it { expect(offer).to have_many(:documents) }
      it { expect(offer).to have_one(:opportunity) }
    end

    describe "when a comparison document is added" do
      let(:pdf) { PdfGenerator::Generator.encode_pdf("dummy pdf") }

      it "should add a comparison doc" do
        offer.add_new_offer_comparison(pdf)
        offer.save!
        expect(offer.comparison_doc).to be_a(Document)
      end

      it "should add a comparison doc for a cover switch" do
        offer.add_switch_offer_comparison(pdf)
        offer.save!
        expect(offer.comparison_doc).to be_a(Document)
      end
    end

    # State Machine: extracted into spec/models/offer_state_machine_spec.rb

    context "callbacks" do
      context "automatic expiration on load" do
        it "expires the offer on load if the valid_until time is reached" do
          offer = create(:offer, state: "active", valid_until: 1.minute.ago, opportunity: @opportunity,
                                 mandate: @mandate)
          offer.reload
          expect(offer).to be_expired
        end

        it "does not expire the offer on load if the valid_until time is not reached" do
          offer = create(:offer, state: "active", valid_until: 1.minute.from_now, opportunity: @opportunity,
                                 mandate: @mandate)
          offer.reload
          expect(offer).not_to be_expired
        end
      end
    end

    describe "scopes" do
      describe "public class methods" do
        context "#without_iban" do
          it "returns offers without IBAN" do
            mandate_with_iban = create :mandate, iban: "DE89 3704 0044 0532 0130 00", active_address: @address
            create :offer, mandate: mandate_with_iban, opportunity: @opportunity

            mandate_without_iban = create :mandate, iban: nil, active_address: @address
            offer_without_iban   = create :offer, mandate: mandate_without_iban, opportunity: @opportunity

            expect(Offer.without_iban).to eq([offer_without_iban])
          end
        end

        context "#older_than" do
          it "returns offers older than a given date" do
            mandate   = create :mandate, active_address: @address
            offer_old = create :offer, created_at: 35.days.ago, mandate: mandate, opportunity: @opportunity
            create :offer, created_at: 25.days.ago, mandate: mandate, opportunity: @opportunity

            expect(Offer.older_than(30.days.ago)).to eq([offer_old])
          end
        end

        context "#of_category" do
          it "returns only offers of the given category id" do
            first_offer = create(:offer, mandate: @mandate, opportunity: @opportunity)
            second_offer = create(:offer, mandate: @mandate, opportunity: create(:opportunity, admin: @admin,
                                                                                               mandate: @mandate))
            expect(Offer.of_category(first_offer.category)).to eq([first_offer])
          end
        end

        context "#not_of_category" do
          it "returns only offers not of the given category id" do
            first_offer = create(:offer, mandate: @mandate, opportunity: @opportunity)
            second_offer = create(:offer, mandate: @mandate, opportunity: create(:opportunity, admin: @admin,
                                                                                               mandate: @mandate))
            expect(Offer.not_of_category(first_offer.category)).to eq([second_offer])
          end
        end
      end

      describe "public instance methods" do
        context "old_product" do
          let(:offer)   { create(:offer, opportunity: @opportunity, mandate: @mandate) }
          let(:product) { create(:product, mandate: @mandate, plan: @plan) }

          it "creates an offer option when setting the old_product" do
            expect { offer.old_product = product }.to change { OfferOption.count }.by(1)
            expect(offer.offer_options.count).to eq(1)
            expect(offer.offer_options.first.product).to eq(product)
            expect(offer.offer_options.first).to be_old_product
          end

          it "changes the existing offer option to the new old_product" do
            other_product = create(:product, mandate: @mandate, plan: @plan)
            offer.offer_options.create(
              product: @product, option_type: OfferOption.option_types[:old_product]
            )

            expect { offer.old_product = other_product }.not_to change { OfferOption.count }

            offer_option = offer.offer_options.find_by(
              option_type: OfferOption.option_types[:old_product]
            )
            expect(offer.offer_options.count).to eq(1)
            expect(offer_option.product).to eq(other_product)
            expect(offer_option).to be_old_product
          end

          it "deletes the offer option when old_product is set to nil" do
            offer.offer_options.create(
              product: @product, option_type: OfferOption.option_types[:old_product]
            )

            expect {
              offer.old_product = nil
            }.to change { OfferOption.count }.by(-1)

            expect(offer.old_product).to be_nil
            expect(offer.offer_options.count).to eq(0)
          end
        end
      end
    end
  end

  context "#cheapest_option" do
    let(:cheap) { ((1000 * rand) + 2).floor } # cents
    let(:expensive) { cheap + 1 } # cents

    let(:cheapest_option) { create_option(cheap) }
    let(:cheapest_option_wrong_labelled) { create_option(cheap, "top_cover") }

    let(:labelled_wrong_top_price) { create_option(expensive) }
    let(:labelled_wrong_top_cover_and_price) { create_option(expensive, "top_cover_and_price") }
    let(:old_product_option_cheapest) { create_option(cheap - 1, "old_product") }

    let(:expensive_option_1) { create_option(expensive, "top_cover", "year", true) }
    let(:expensive_option_2) { create_option(expensive, "top_cover") }

    def create_option(price_cents, type="top_price", period="year", recommend=false)
      option = create(
        :offer_option,
        option_type: type,
        recommended: recommend,
        product:     create(
          :product,
          state:               "offered",
          premium_price_cents: price_cents,
          premium_period:      period,
          mandate:             @mandate,
          category:            @category,
          company:             @company,
          plan:                @plan
        )
      )
      option
    end

    def new_offer(*offer_options)
      build(:offer, offer_options: offer_options, opportunity: @opportunity, mandate: @mandate)
    end

    it "should choose a single option if it's the only one" do
      offer = new_offer(expensive_option_1)
      expect(offer.cheapest_new_option).to eq(expensive_option_1)
    end

    it "should choose the cheapest option out of several" do
      offer = new_offer(expensive_option_1, cheapest_option, expensive_option_2)
      expect(offer.cheapest_new_option).to eq(cheapest_option)
    end

    it "should choose the cheapest option also if labeled not labelled as cheapest" do
      offer = new_offer(expensive_option_1, labelled_wrong_top_price, cheapest_option)
      expect(offer.cheapest_new_option).to eq(cheapest_option)
    end

    it "should choose the cheapest option also if not labelled as top cover and price" do
      offer = new_offer(expensive_option_1, cheapest_option_wrong_labelled, expensive_option_2)
      expect(offer.cheapest_new_option).to eq(cheapest_option_wrong_labelled)
    end

    it "should not choose the old product, if it's the cheapest" do
      offer = new_offer(old_product_option_cheapest, cheapest_option, expensive_option_1)
      expect(offer.cheapest_new_option).to eq(cheapest_option)
    end

    it "should not choose an option that is more expensive do to shorter premium period" do
      monthly_payment_option = create_option(cheap - 1, "top_price", "month")
      offer = new_offer(expensive_option_1, cheapest_option, monthly_payment_option)
      expect(offer.cheapest_new_option).to eq(cheapest_option)
    end
  end

  describe "#note_to_customer" do
    let(:offer) { build(:offer, {mandate: @mandate, opportunity: @opportunity}.merge(args)) }

    before { @note_to_customer_setting = Settings.offer.note_to_customer.required }

    after { Settings.offer.note_to_customer.required = @note_to_customer_setting }

    context "when setting :required is disabled" do
      before { Settings.offer.note_to_customer.required = false }

      after do
        Settings.reload!
      end

      context "when not present" do
        let(:args) { {note_to_customer: ""} }

        it "is valid" do
          expect(offer).to be_valid
        end
      end
    end
  end

  describe "#vvg_attached_to_offer validation", :integration do
    let(:vvg_information_package) { DocumentType.vvg_information_package }
    let(:medium_margin_category) { create(:category, :medium_margin) }
    let(:opportunity) { create(:opportunity, category: medium_margin_category) }
    let(:offer) { create(:active_offer, opportunity: opportunity, state: "in_creation") }
    let(:error_message_translation) { I18n.t("activerecord.errors.models.offer.missed_vvg_information_package") }
    let(:gkv_category) { create(:category_gkv, margin_level: "high") }

    context "with attached 'vvg_information_package'" do
      before do
        offer.offer_options.each do |option|
          create :document, document_type: vvg_information_package, documentable: option.product
        end
      end

      it "it makes 'offer' transition to the 'active' state for medium margin" do
        offer.send_offer

        expect(offer.state).to eq("active")
      end

      it "it makes 'offer' transition to the 'active' state for high margin" do
        opportunity.category.update(margin_level: "high")
        offer.send_offer

        expect(offer.state).to eq("active")
      end

      it "it makes 'offer' transition to the 'active' state for low margin" do
        opportunity.category.update(margin_level: "low")
        offer.send_offer

        expect(offer.state).to eq("active")
        expect(opportunity.state).to eq("offer_phase")
      end

      it "it makes 'offer' transition to the 'active' state for gkv" do
        opportunity.update(category_id: gkv_category.id)
        offer.send_offer

        expect(offer.state).to eq("active")
      end

      context "when opportunity already is in 'offer_phase' state" do
        before do
          opportunity.category.update(margin_level: "low")
          opportunity.update(state: :offer_phase)
        end

        it "it makes 'offer' transition to the 'active' state for low margin" do
          offer.send_offer

          expect(offer.state).to eq("active")
          expect(opportunity.state).to eq("offer_phase")
        end

        it "sends an opportunity transition error to the Sentry" do
          expect(Raven).to receive(:capture_exception).at_least(:once)

          offer.send_offer
        end
      end
    end

    context "without attached 'vvg_information_package'" do
      it "it got an validation error for medium margin" do
        offer.send_offer

        expect(offer.errors.messages[:state]).to include(error_message_translation)
        expect(offer.state).to eq("in_creation")
      end

      it "it got an validation error for high margin" do
        opportunity.category.update(margin_level: "high")
        offer.send_offer

        expect(offer.errors.messages[:state]).to include(error_message_translation)
        expect(offer.state).to eq("in_creation")
      end

      it "it makes offer transition to 'active' for low margin" do
        opportunity.category.update(margin_level: "low")
        offer.send_offer

        expect(offer.state).to eq("active")
      end

      it "it makes offer transition to 'active' for gkv" do
        opportunity.update(category_id: gkv_category.id)
        offer.send_offer

        expect(offer.state).to eq("active")
      end
    end
  end
end
