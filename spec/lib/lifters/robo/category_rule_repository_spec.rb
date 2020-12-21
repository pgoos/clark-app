# frozen_string_literal: true

require "rails_helper"

describe Robo::CategoryRuleRepository, integration: true do
  subject { described_class.new }

  describe "#enabled_rule_ids" do
    it "returns an array of enabled rule ids for given category ident" do
      category1 = create :category
      category2 = create :category

      create :category_rule, :enabled,  category_ident: category1.ident, rule_id: "RULE_1"
      create :category_rule, :disabled, category_ident: category1.ident, rule_id: "RULE_2"
      create :category_rule, :enabled,  category_ident: category1.ident, rule_id: "RULE_3"
      create :category_rule, :enabled,  category_ident: category2.ident, rule_id: "RULE_4"

      expect(subject.enabled_rule_ids(category1.ident)).to match_array %w[RULE_1 RULE_3]
    end
  end
end
