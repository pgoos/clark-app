# frozen_string_literal: true

require "rails_helper"

RSpec.describe MandatesRepository, :integration do
  subject { described_class.new }

  describe ".all_in_campaign_by_ident" do
    let(:mandate_in_campaign) { create(:mandate, :accepted, user: create(:user)) }
    let(:category_in_campaign) { create(:category, ident: "1c59e870") }

    let(:mandate_out_of_scope) { create(:mandate, :accepted, user: create(:user)) }
    let(:category_out_of_scope) { create(:category, ident: "rubbish") }

    let(:mandate_in_campaign_two) { create(:mandate, :accepted, user: create(:user)) }
    let(:category_in_campaign_two) { create(:category, ident: "d55e03e6") }

    let(:category_idents) { %w[d9c5a3fe 1c59e870 a37cd85a 58680af3 d55e03e6 b4576bcf 15f6b555].freeze }

    before do
      create(:product,
             plan: create(:plan, category_id: category_in_campaign.id),
             mandate: mandate_in_campaign)
    end

    it "returns mandate with product included in the campaign" do
      expect(subject.all_in_campaign_by_ident(category_idents)).to match_array([mandate_in_campaign])
    end

    context "when a mandate with product with category id not in campaign is present" do
      before do
        create(:product,
               plan: create(:plan, category_id: category_out_of_scope.id),
               mandate: mandate_out_of_scope)
      end

      it "is ignored in the result of the scope" do
        expect(subject.all_in_campaign_by_ident(category_idents)).to match_array([mandate_in_campaign])
      end
    end

    context "when a mandate with product with category in campign is added" do
      before do
        create(:product,
               plan: create(:plan, category_id: category_in_campaign_two.id),
               mandate: mandate_in_campaign_two)
      end

      it "is returned as part of the scope" do
        expect(subject.all_in_campaign_by_ident(category_idents)).to match_array([mandate_in_campaign,
                                                                                  mandate_in_campaign_two])
      end
    end

    context "when a mandate with product with category in campaign is added but with variety as critic or vip" do
      before do
        create(:product,
               plan: create(:plan, category_id: category_in_campaign_two.id),
               mandate: mandate_in_campaign_two)
        mandate_in_campaign_two.variety = "critic"
        mandate_in_campaign_two.save!
      end

      it "does not return it as part of the scope" do
        expect(subject.all_in_campaign_by_ident(category_idents)).to match_array([mandate_in_campaign])
      end
    end

    context "when a mandate with product with category in campaign is added but with non active product state " do
      before do
        create(:product,
               state: "offered",
               plan: create(:plan, category_id: category_in_campaign_two.id),
               mandate: mandate_in_campaign_two)
      end

      it "does not return it as part of the scope" do
        expect(subject.all_in_campaign_by_ident(category_idents)).to match_array([mandate_in_campaign])
      end
    end

    context "when a mandate with product with category in campaign is added but has unsubscribed" do
      before do
        mandate_in_campaign_two.user.subscriber = false
        mandate_in_campaign_two.user.save!
        create(:product,
               state: "offered",
               plan: create(:plan, category_id: category_in_campaign_two.id),
               mandate: mandate_in_campaign_two)
      end

      it "does not return it as part of the scope" do
        expect(subject.all_in_campaign_by_ident(category_idents)).to match_array([mandate_in_campaign])
      end
    end

    context "when a mandate with product with category in campaign is added but has owner not clark or malburg" do
      before do
        mandate_in_campaign_two.owner_ident = "some other"
        mandate_in_campaign_two.save!
        create(:product,
               state: "offered",
               plan: create(:plan, category_id: category_in_campaign_two.id),
               mandate: mandate_in_campaign_two)
      end

      it "does not return it as part of the scope" do
        expect(subject.all_in_campaign_by_ident(category_idents)).to match_array([mandate_in_campaign])
      end
    end

    context "when a mandate with product with category in campign is added but the already has the email sent" do
      before do
        create(:product,
               plan: create(:plan, category_id: category_in_campaign_two.id),
               mandate: mandate_in_campaign_two)
        mandate_in_campaign_two.documents << create(:document, document_type: DocumentType.kfz_switching,
                                                               created_at: 2.days.ago)
      end

      it "does not return it as part of the scope" do
        expect(subject.all_in_campaign_by_ident(category_idents, document_type_id: DocumentType.kfz_switching.id))
          .to match_array([mandate_in_campaign])
      end
    end

    context "when a mandate with product with category in campign is added but the product is sold by clark" do
      before do
        create(:product,
               :sold_by_us,
               plan: create(:plan, category_id: category_in_campaign_two.id),
               mandate: mandate_in_campaign_two)
      end

      it "does not return it as part of the scope" do
        expect(subject.all_in_campaign_by_ident(category_idents, document_type_id: DocumentType.kfz_switching.id))
          .to match_array([mandate_in_campaign])
      end
    end

    context "when a mandate with product with category in campign is added but the mandate is revoked" do
      before do
        create(:product,
               :sold_by_us,
               plan: create(:plan, category_id: category_in_campaign_two.id),
               mandate: mandate_in_campaign_two)
        mandate_in_campaign_two.state = "revoked"
        mandate_in_campaign_two.save!
      end

      it "does not return it as part of the scope" do
        expect(subject.all_in_campaign_by_ident(category_idents, document_type_id: DocumentType.kfz_switching.id))
          .to match_array([mandate_in_campaign])
      end
    end
  end

  describe "#find" do
    context "when there is a mandate" do
      it "returns the mandate" do
        mandate = create(:mandate)

        m = described_class.find(mandate.id)
        expect(m).not_to be nil
        expect(m.state).to eq(mandate.state)
        expect(m.customer_state).to eq(mandate.customer_state)
      end
    end
  end

  describe "#older_than_14_days" do
    let(:mandate) { create(:mandate) }

    context "when customer is older than 14 days" do
      let(:metadata) { { customer_state: { new: :self_service, old: :prospect } } }

      before { create(:business_event, entity: mandate, created_at: 14.days.ago, metadata: metadata) }

      it "returns true" do
        expect(described_class.older_than_14_days?(mandate.id)).to be true
      end
    end

    context "when customer is not older than 14 days" do
      let(:metadata) { { state: { new: :accepted, old: :created } } }

      before { create(:business_event, entity: mandate, created_at: 10.days.ago, metadata: metadata) }

      it "returns false" do
        expect(described_class.older_than_14_days?(mandate.id)).to be false
      end
    end
  end
end
