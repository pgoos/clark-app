# frozen_string_literal: true

# == Schema Information
#
# Table name: interactions
#
#  id           :integer          not null, primary key
#  type         :string
#  mandate_id   :integer
#  admin_id     :integer
#  topic_id     :integer
#  topic_type   :string
#  direction    :string
#  content      :text
#  metadata     :jsonb
#  acknowledged :boolean
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require "rails_helper"

RSpec.describe Interaction, type: :model do
  # Setup
  subject { build_stubbed(:interaction) }

  # Settings
  # Constants
  # Attribute Settings
  # Plugins

  # Concerns
  it_behaves_like "an auditable model"

  # State Machine

  # Scopes
  include_examples "between_scopeable", :created_at, -> { FactoryBot.create(:mandate) }

  describe ".warmup_calls" do
    it "returns an empty array if no phone calls with sales warmup type found" do
      expect(described_class.warmup_calls).to eq([])
    end

    it "returns only phone call interactions with sales warmup type" do
      create(
        :interaction_phone_call, call_type: Interaction::PhoneCall.call_types[:sales]
      )

      second_phone_call = create(
        :interaction_phone_call, call_type: Interaction::PhoneCall.call_types[:sales_warmup]
      )

      expect(described_class.warmup_calls).to eq([second_phone_call])
    end
  end

  describe ".welcome_calls" do
    it "returns an empty array if no phone calls with mandate welcome type found" do
      expect(described_class.welcome_calls).to eq([])
    end

    it "returns only phone call interactions with mandate welcome type" do
      create(
        :interaction_phone_call, call_type: Interaction::PhoneCall.call_types[:sales]
      )

      second_phone_call = create(
        :interaction_phone_call, call_type: Interaction::PhoneCall.call_types[:mandate_welcome]
      )

      expect(described_class.welcome_calls).to eq([second_phone_call])
    end
  end

  # Associations

  it { expect(subject).to belong_to(:mandate) }
  it { expect(subject).to belong_to(:admin) }
  it { expect(subject).to belong_to(:topic) }

  # DB
  it { is_expected.to have_db_index(:created_at) }

  # Nested Attributes
  # Validations
  # Callbacks
  # Instance Methods
  describe ".acknowledge!", :integration do
    context "interaction already acknowledge" do
      let(:interaction) { create(:incoming_message, :read) }

      it "return nil" do
        expect(interaction.acknowledge!).to be(nil)
      end

      it "generate no business events at all" do
        interaction
        expect(BusinessEvent).not_to receive(:audit)
        interaction.acknowledge!
      end
    end

    context "interaction not acknowledge" do
      let(:interaction) { create(:incoming_message, :unread) }

      it "update acknowledge in interaction" do
        interaction.acknowledge!
        expect(interaction.acknowledged?).to be(true)
      end

      it "generate update and mark_as_resolved business events only" do
        expect(BusinessEvent).to receive(:audit).with(interaction, "update")
        expect(BusinessEvent).to receive(:audit).with(interaction, "mark_as_resolved")
        interaction.acknowledge!
      end
    end
  end

  # Class Methods

  describe ".allowed_for?" do
    before do
      allow(Features).to receive(:inactive?).and_call_original
    end

    context "customer that acquired by Clark" do
      let(:mandate) { create(:mandate) }
      let(:product) { create(:product, mandate: mandate) }

      it "returns true" do
        expect(described_class).to be_allowed_for(mandate, :sms)
      end

      context "instant advice feature switch is ON" do
        before do
          allow(Features).to receive(:inactive?).with(Features::INSTANT_ADVICE).and_return(false)
        end

        context "instant advice available" do
          before { allow(Contracts).to receive_message_chain(:instant_advice, :failure?).and_return(false) }

          it "returns false" do
            expect(described_class).not_to be_allowed_for(product, :advice)
            expect(described_class).not_to be_allowed_for(product, :advice_reply)
          end
        end

        context "instant advice not available" do
          before { allow(Contracts).to receive_message_chain(:instant_advice, :failure?).and_return(true) }

          it "returns true" do
            expect(described_class).to be_allowed_for(product, :advice)
            expect(described_class).to be_allowed_for(product, :advice_reply)
          end
        end

        context "product has no category" do
          before { allow(Contracts).to receive_message_chain(:instant_advice, :failure?).and_return(true) }

          let(:product) { create(:product, mandate: mandate, category: nil) }

          it "returns false when passing product" do
            expect(described_class).not_to be_allowed_for(product, :advice)
            expect(described_class).not_to be_allowed_for(product, :advice_reply)
          end

          it "returns false when passing decorated product" do
            expect(described_class).not_to be_allowed_for(product.decorate, :advice)
            expect(described_class).not_to be_allowed_for(product.decorate, :advice_reply)
          end
        end

        context "product has no company" do
          before { allow(Contracts).to receive_message_chain(:instant_advice, :failure?).and_return(true) }

          let(:product) { create(:product, mandate: mandate, company: nil) }

          it "returns false when passing product" do
            expect(described_class).not_to be_allowed_for(product, :advice)
            expect(described_class).not_to be_allowed_for(product, :advice_reply)
          end

          it "returns false when passing decorated product" do
            expect(described_class).not_to be_allowed_for(product.decorate, :advice)
            expect(described_class).not_to be_allowed_for(product.decorate, :advice_reply)
          end
        end

        context "product has no company and no category" do
          before { allow(Contracts).to receive_message_chain(:instant_advice, :failure?).and_return(true) }

          let(:product) { create(:product, mandate: mandate, company: nil, category: nil) }

          it "returns false when passing product" do
            expect(described_class).not_to be_allowed_for(product, :advice)
            expect(described_class).not_to be_allowed_for(product, :advice_reply)
          end

          it "returns false when passing decorated product" do
            expect(described_class).not_to be_allowed_for(product.decorate, :advice)
            expect(described_class).not_to be_allowed_for(product.decorate, :advice_reply)
          end
        end
      end

      it "returns true for an advice when a instant advice feature switch is OFF" do
        allow(Features).to receive(:inactive?).with(Features::INSTANT_ADVICE).and_return(true)
        expect(described_class).to be_allowed_for(product, :advice)
        expect(described_class).to be_allowed_for(product, :advice_reply)
      end
    end

    context "customer that acquired by a partner" do
      let(:mandate) do
        create(:mandate, owner_ident: "some_partner_ident",
                                      user:        create(:user))
      end

      it "returns true for an email interaction" do
        expect(described_class).to be_allowed_for(mandate, :email)
      end

      it "returns true for a phone interaction" do
        expect(described_class).to be_allowed_for(mandate, :phone_call)
      end

      it "returns true for a messenger interaction when a customer has logged in at least once" do
        mandate.user.sign_in_count = 10
        expect(described_class).to be_allowed_for(mandate, :message)
      end

      it "returns false for other types of interactions" do
        expect(described_class).not_to be_allowed_for(mandate, :other_interaction)
      end

      it "returns false for a messenger interaction when a customer has not logged in" do
        mandate.reload
        expect(described_class).not_to be_allowed_for(mandate, :message)
      end
    end
  end
end
