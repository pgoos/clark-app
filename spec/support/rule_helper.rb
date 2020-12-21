# frozen_string_literal: true
module RuleHelper
  class << self
    def simulate_execution(subject, candidate, mandate)
      subject.trace_run(candidate, {status: "OK", ident: subject.name}, mandate)
      subject.trace_result(candidate, {status: "OK", ident: subject.name}, mandate)
    end

    def derive_candidate(base, options)
      derivation = base.to_h.dup
      OpenStruct.new(derivation.merge(options))
    end
  end
end
