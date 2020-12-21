# frozen_string_literal: true

RSpec.shared_examples "when product is already advised in dispatcher spec" do
  before { create(:interaction_advice, product: product, mandate: mandate) }

  it "should not create an interaction" do
    expect { subject.(mandate, product, template, rule_id) }.to \
      change(Interaction::Advice, :count).by(0)
  end

  it "should not schedule ReoccurringAdviceJob" do
    expect { subject.(mandate, product, template, rule_id) }
      .not_to have_enqueued_job(ReoccurringAdviceJob)
  end
end

RSpec.shared_examples "when product is already advised in advice spec" do
  before { create(:interaction_advice, product: interaction.product, mandate: mandate) }

  it "should not create a interaction" do
    subject.dispatch
    expect(interaction).not_to be_persisted
  end
end
