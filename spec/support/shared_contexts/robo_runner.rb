# frozen_string_literal: true

RSpec.shared_context "with mocked roboadvisor" do
  before do
    create :category_rule, category_ident: category.ident, rule_id: rule_id
    create :category_rule, category_ident: category.ident, rule_id: "FOO_RULE"

    allow(Roboadvisor).to receive(:process) \
      .with(
        product.id,
        match_array([rule_id, "FOO_RULE"])
      )
      .and_return(rule_id)
  end
end
