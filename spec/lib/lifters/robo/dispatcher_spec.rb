# frozen_string_literal: true

require "rails_helper"

describe Robo::Dispatcher do
  subject { described_class.new }

  let!(:admin)  { create :advice_admin }
  let(:mandate) { create :mandate, last_advised_at: last_advised_at }
  let(:product) { create :product, :phv, mandate: mandate }
  let(:rule_id) { "RULE_ID" }

  let(:template) do
    Robo::Advices::Template.new(
      classification: :keeper,
      text: "ADVICE TEXT",
      cta: Robo::Advices::Cta.new(
        text: "CTA TEXT",
        link: "http://foo.bar"
      )
    )
  end

  context "when first advice of the day" do
    let(:last_advised_at) { 1.day.ago }

    it "creates an interaction with correct values" do
      expect { subject.(mandate, product, template, rule_id) }.to \
        change(Interaction::Advice, :count).by(1)

      interaction = mandate.interactions.last
      expect(interaction).to be_present
      expect(interaction.topic).to eq product
      expect(interaction.admin).to eq admin
      expect(interaction.content).to eq "ADVICE TEXT"
      expect(interaction.cta_link).to eq "http://foo.bar"
      expect(interaction.cta_text).to eq "CTA TEXT"
      expect(interaction.disable_reply).to be true
      expect(interaction.rule_id).to eq "RULE_ID"
      expect(interaction.created_by_robo_advisor).to be true
      expect(interaction.reoccurring_advice).to be true
      expect(interaction.classifications).to eq ["keeper"]
    end

    it "updates mandate's last_advised_at date" do
      expect { subject.(mandate, product, template, rule_id) }.to \
        change(mandate, :last_advised_at)
    end

    it "initiates to notify customer" do
      interaction = Interaction::Advice.new(
        mandate: mandate,
        topic: product,
        admin_id: Robo::AdminRepository.random,
        created_by_robo_advisor: true,
        reoccurring_advice: true,
        rule_id: rule_id,
        content: template.text,
        cta_link: template.cta.link,
        cta_text: template.cta.text,
        disable_reply: false
      )
      advice = Domain::Interactions::Advice.new(mandate: mandate, interaction: interaction)

      allow(Interaction::Advice).to receive(:new).and_return(interaction)
      allow(interaction).to receive(template.classification).and_return(interaction)

      expect(Domain::Interactions::Advice).to \
        receive(:new).with(mandate: mandate, interaction: interaction).and_return(advice)

      expect(advice).to receive(:dispatch)

      subject.(mandate, product, template, rule_id)
    end

    it_behaves_like "when product is already advised in dispatcher spec"

    context "inactive advice exists" do
      context "contents match" do
        let!(:last_advice) do
          create(:advice,
                 :reoccurring_advice,
                 valid: false,
                 content: template.text,
                 product: product)
        end

        it "does not create new advice" do
          expect { subject.(mandate, product, template, rule_id) }.to \
            change(Interaction::Advice, :count).by(0)
        end

        it "marks last advice valid" do
          subject.(mandate, product, template, rule_id)
          expect(last_advice.reload.valid).to be_truthy
        end
      end

      context "contents differ" do
        let!(:last_advice) do
          create(:advice,
                 :reoccurring_advice,
                 valid: false,
                 content: "Brand new advice that will change customer's life",
                 product: product)
        end

        it "creates new advice" do
          expect { subject.(mandate, product, template, rule_id) }.to \
            change(Interaction::Advice, :count).by(1)
        end

        it "marks last advice valid" do
          subject.(mandate, product, template, rule_id)
          expect(last_advice.reload.valid).to be_truthy
        end
      end
    end
  end

  context "when it's not the first advice of the day" do
    let(:last_advised_at) { Time.zone.now }

    it "should not create an interaction" do
      expect { subject.(mandate, product, template, rule_id) }.to \
        change(Interaction::Advice, :count).by(0)
    end

    it "should schedule a ReoccurringAdviceJob next day for the same product" do
      expect { subject.(mandate, product, template, rule_id) }
        .to have_enqueued_job(ReoccurringAdviceJob)
        .with(wait: 1.day)
        .with(product.id)
        .exactly(:once)
    end

    it_behaves_like "when product is already advised in dispatcher spec"
  end
end
