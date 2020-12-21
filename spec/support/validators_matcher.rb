# frozen_string_literal: true

RSpec::Matchers.define :validate_rule do |attribute, expected|
  match do |contract|
    rules = contract.rules.select { |rule| rule.keys.include?(attribute) }
    rules.map(&:macros).flatten.include?(expected.to_sym)
  end

  failure_message do |contract|
    current_rules = contract.rules.map do |rule|
      {
        attributes: rule.keys,
        macros: rule.macros.flatten
      }
    end
    "expected \"#{attribute}\" to be validated with \"#{expected}\" macro
      current validations: #{current_rules}"
  end
end
