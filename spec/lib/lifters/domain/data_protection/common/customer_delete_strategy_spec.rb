# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::DataProtection::Common::CustomerDeleteStrategy, :integration do
  subject do
    described_class.new(
      admin,
      mandate,
      skip_notification_email: skip_notification_email
    )
  end

  let(:skip_notification_email) { false }

  let(:call) { subject.run }

  let(:admin) { create(:admin) }
  let(:user) { create(:user) }
  let!(:mandate) { create(:mandate, user: user, state: "accepted") }

  describe "#run" do
    describe "deletion of related appointments" do
      let!(:appointment) do
        create(
          :appointment,
          mandate: mandate,
          appointable: build(:opportunity, mandate: mandate)
        )
      end
      let!(:document) { create(:document, documentable: appointment) }
      let!(:business_event) { create(:business_event, entity: appointment, person: admin) }

      it do
        expect { call }.to(
          change_counters
            .from(
              Appointment => 1,
              Document => 1,
              Opportunity => 1,
              BusinessEvent => 1,
              Mandate => 1
            )
            .to_zeros
        )
      end
    end

    describe "deletion of related documents" do
      let!(:document) { create(:document, documentable: mandate) }
      let!(:business_event) { create(:business_event, entity: document, person: admin) }

      it do
        expect { call }.to(
          change_counters
            .from(
              Document => 1,
              BusinessEvent => 1,
              Mandate => 1
            )
            .to_zeros
        )
      end
    end

    describe "deletion of related follow ups" do
      let!(:follow_up) { create(:follow_up, item: mandate) }
      let!(:business_event) { create(:business_event, entity: follow_up, person: admin) }

      it do
        expect { call }.to(
          change_counters
            .from(
              FollowUp => 1,
              BusinessEvent => 1,
              Mandate => 1
            )
            .to_zeros
        )
      end
    end

    describe "deletion of related insurance comparisons" do
      let!(:insurance_comparison) do
        create(
          :insurance_comparison,
          mandate: mandate,
          opportunity: build(:opportunity, mandate: mandate)
        )
      end
      let!(:document) { create(:document, documentable: insurance_comparison) }
      let!(:business_event) { create(:business_event, entity: insurance_comparison, person: admin) }

      it do
        expect { call }.to(
          change_counters
            .from(
              InsuranceComparison => 1,
              Document => 1,
              Opportunity => 1,
              BusinessEvent => 1,
              Mandate => 1
            )
            .to_zeros
        )
      end
    end

    describe "deletion of related interactions" do
      let!(:interaction) { create(:interaction, mandate: mandate) }
      let!(:business_event) { create(:business_event, entity: interaction, person: admin) }

      it do
        expect { call }.to(
          change_counters
            .from(
              Interaction => 1,
              BusinessEvent => 1,
              Mandate => 1
            )
            .to_zeros
        )
      end
    end

    describe "deletion of related opportunities" do
      let!(:opportunity) do
        create(
          :opportunity,
          mandate: mandate,
          follow_ups: [build(:follow_up)],
          interactions: [build(:interaction, mandate: mandate)]
        )
      end
      let!(:insurance_comparison) do
        create(
          :insurance_comparison,
          mandate: mandate,
          opportunity: opportunity
        )
      end
      let!(:document) { create(:document, documentable: opportunity) }
      let!(:comment) { create(:comment, commentable: opportunity, admin: admin) }
      let!(:business_event) { create(:business_event, entity: opportunity, person: admin) }

      it do
        expect { call }.to(
          change_counters
            .from(
              Opportunity => 1,
              Comment => 1,
              Document => 1,
              FollowUp => 1,
              InsuranceComparison => 1,
              Interaction => 1,
              BusinessEvent => 1,
              Mandate => 1
            )
            .to_zeros
        )
      end
    end

    describe "deletion of related offers (part 1)" do
      let!(:offer) do
        create(
          :offer,
          mandate: mandate,
          opportunity: build(:opportunity, mandate: mandate)
        )
      end
      let!(:business_event) { create(:business_event, entity: offer, person: admin) }

      it do
        expect { call }.to(
          change_counters
            .from(
              Offer => 1,
              BusinessEvent => 1,
              Mandate => 1
            )
            .to_zeros
        )
      end
    end

    describe "deletion of related offer (part 2)" do
      let!(:offer) do
        create(
          :offer,
          mandate: mandate,
          opportunity: build(:opportunity, mandate: mandate),
          interactions: [build(:interaction, mandate: mandate)],
          follow_ups: [build(:follow_up)]
        )
      end
      let!(:document) { create(:document, documentable: offer) }

      it do
        expect { call }.to(
          change_counters
            .from(
              Offer => 1,
              Opportunity => 1,
              FollowUp => 1,
              Interaction => 1,
              Document => 1,
              Mandate => 1
            )
            .to_zeros
        )
      end
    end

    describe "deletion of related offer (part 3)" do
      let!(:offer) do
        create(
          :offer,
          mandate: mandate,
          opportunity: build(:opportunity, mandate: mandate)
        )
      end

      let!(:offer_option) { create(:offer_option, offer: offer) }

      it do
        expect { call }.to(
          change_counters
            .from(
              Offer => 1,
              OfferOption => 1,
              Mandate => 1
            )
            .to_zeros
        )
      end
    end

    describe "deletion of related profile data" do
      let!(:profile_data) { create(:profile_datum, mandate: mandate) }
      let!(:business_event) { create(:business_event, entity: profile_data, person: admin) }

      it do
        expect { call }.to(
          change_counters
            .from(
              ProfileDatum => 1,
              BusinessEvent => 1,
              Mandate => 1
            )
            .to_zeros
        )
      end
    end

    describe "deletion of related recommendations" do
      let!(:recommendation) { create(:recommendation, mandate: mandate) }
      let!(:business_event) { create(:business_event, entity: recommendation, person: admin) }

      it do
        expect { call }.to(
          change_counters
            .from(
              Recommendation => 1,
              BusinessEvent => 1,
              Mandate => 1
            )
            .to_zeros
        )
      end
    end

    describe "deletion of related products (part 1)" do
      let!(:product) do
        create(
          :product,
          mandate: mandate,
          accounting_transactions: [build(:accounting_transaction)],
          follow_ups: [build(:follow_up)],
          opportunities: [build(:opportunity, mandate: mandate)],
          premium_price_cents: 11_000,
          premium_price_currency: "EUR",
          premium_period: :year
        )
      end
      let!(:offer_option) { create(:offer_option, product: product) }
      let!(:document) { create(:document, documentable: product) }
      let(:data_attribute) do
        {
          gender: mandate.gender,
          premium: {value: 110.0, currency: "EUR"},
          replacement_premium: {value: 70.0, currency: "EUR"},
          premium_period: :year
        }
      end
      let!(:product_partner_data) do
        create(
          :product_partner_datum,
          product: product,
          data: data_attribute
        )
      end
      let!(:comment) { create(:comment, commentable: product, admin: admin) }
      let!(:business_event) { create(:business_event, entity: product, person: admin) }

      it do
        expect { call }.to(
          change_counters
            .from(
              Product => 1,
              OfferOption => 1,
              Accounting::Transaction => 1,
              Comment => 1,
              Document => 1,
              FollowUp => 1,
              Opportunity => 1,
              ProductPartnerDatum => 1,
              BusinessEvent => 1,
              Mandate => 1
            )
            .to_zeros
        )
      end
    end

    describe "deletion of related products (part 2)" do
      let!(:product) do
        create(
          :product,
          mandate: mandate,
          interactions: [build(:interaction, mandate: mandate)]
        )
      end
      let!(:advice) { create(:advice, mandate: mandate, product: product) }

      it do
        expect { call }.to(
          change_counters
            .from(
              Product => 1,
              Interaction => 2,
              Mandate => 1
            )
            .to_zeros
        )
      end
    end

    describe "deletion of related inquires" do
      let!(:inquiry) do
        create(
          :inquiry,
          mandate: mandate,
          follow_ups: [build(:follow_up)],
          interactions: [build(:interaction, mandate: mandate)],
          products: [build(:product, mandate: mandate)]
        )
      end

      let!(:inquiry_document) { create(:document, documentable: inquiry) }

      let!(:inquiry_category) do
        create(
          :inquiry_category,
          inquiry: inquiry
        )
      end

      let!(:inquiry_category_document) do
        create(:document, documentable: inquiry_category)
      end

      let!(:inquiry_comment) do
        create(:comment, commentable: inquiry, admin: admin)
      end

      let!(:inquiry_category_comment) do
        create(:comment, commentable: inquiry_category, admin: admin)
      end

      let!(:inquiry_document_business_event) do
        create(:business_event, entity: inquiry_document, person: admin)
      end

      let!(:inquiry_category_business_event) do
        create(:business_event, entity: inquiry_category, person: admin)
      end

      let!(:inquiry_business_event) do
        create(:business_event, entity: inquiry, person: admin)
      end

      it do
        expect { call }.to(
          change_counters
            .from(
              Inquiry => 1,
              InquiryCategory => 1,
              Document => 2,
              Comment => 2,
              FollowUp => 1,
              Interaction => 1,
              Product => 1,
              BusinessEvent => 3,
              Mandate => 1
            )
            .to_zeros
        )
      end
    end

    describe "deletion of related user" do
      let!(:device) { create(:device, user: user) }
      let!(:document) { create(:document, documentable: user) }
      let!(:follow_up) { create(:follow_up, item: user) }
      let!(:identity) { create(:identity, user: user) }
      let!(:comment) { create(:comment, commentable: user, admin: admin) }

      let!(:device_business_event) { create(:business_event, entity: device, person: admin) }
      let!(:document_business_event) { create(:business_event, entity: document, person: admin) }
      let!(:follow_up_business_event) { create(:business_event, entity: follow_up, person: admin) }
      let!(:identity_business_event) { create(:business_event, entity: identity, person: admin) }
      let!(:business_event) { create(:business_event, entity: user, person: admin) }
      let!(:executed_business_event) { create(:business_event, entity: user, person: user) }

      it do
        expect { call }.to(
          change_counters
            .from(
              User => 1,
              Device => 1,
              Document => 1,
              FollowUp => 1,
              Identity => 1,
              Comment => 1,
              BusinessEvent => 6,
              Mandate => 1
            )
            .to_zeros
        )
      end
    end

    describe "deletion of related questionnaire response" do
      let!(:questionnaire_response) { create(:questionnaire_response, mandate: mandate) }
      let!(:questionnaire_answer) do
        create(:questionnaire_answer, questionnaire_response: questionnaire_response)
      end

      it do
        expect { call }.to(
          change_counters
            .from(
              Questionnaire::Response => 1,
              Questionnaire::Answer => 1,
              Mandate => 1
            )
            .to_zeros
        )
      end
    end

    describe "deletion of directly related records" do
      let!(:comment) { create(:comment, commentable: mandate, admin: admin) }
      let!(:feed_log) { create(:feed_log, mandate: mandate) }
      let!(:loyalty_booking) { create(:loyalty_booking, mandate: mandate) }
      let!(:phone) { create(:phone, mandate: mandate) }
      let!(:signature) { create(:signature, signable: mandate) }
      let!(:retirement_cockpit) { create(:retirement_cockpit, mandate: mandate) }
      let!(:lead) { create(:lead, mandate: mandate) }
      let!(:business_event) { create(:business_event, entity: mandate, person: admin) }
      let!(:shortened_url) do
        mandate.shortened_urls.create!(
          owner: mandate,
          url: "some_dummy_value"
        )
      end

      it do
        expect { call }.to(
          change_counters
            .from(
              Address => 1,
              Comment => 1,
              Feed::Log => 1,
              LoyaltyBooking => 1,
              Phone => 1,
              Shortener::ShortenedUrl => 1,
              Signature => 1,
              Retirement::Cockpit => 1,
              Lead => 1,
              BusinessEvent => 1,
              Mandate => 1
            )
            .to_zeros
        )
      end
    end

    describe "deletion of related tracking events" do
      let!(:tracking_event) { create(:tracking_event, mandate: mandate) }
      let!(:tracking_visit) do
        create(
          :tracking_visit,
          events: [tracking_event]
        )
      end
      let!(:tracking_adjust_event) { create(:tracking_adjust_event, mandate: mandate) }

      it do
        expect { call }.to(
          change_counters
            .from(
              Tracking::Event => 1,
              Tracking::Visit => 1,
              Tracking::AdjustEvent => 1,
              Mandate => 1
            )
            .to_zeros
        )
      end
    end

    describe "Email Notification" do
      context "when skip_notification_email turned off" do
        let(:skip_notification_email) { false }

        it "sends email to admin" do
          receiver = double("Receiver")
          allow(receiver).to receive(:deliver_now)

          expect(DataProtectionMailer).to(
            receive(:deletion_notification)
            .with(admin, mandate.id)
            .and_return(receiver)
          )
          call
        end
      end

      context "when skip_notification_email turned off" do
        let(:skip_notification_email) { true }

        it "sends email to admin" do
          receiver = double("Receiver")
          allow(receiver).to receive(:deliver_now)

          expect(DataProtectionMailer).not_to(
            receive(:deletion_notification)
          )
          call
        end
      end
    end
  end
end
