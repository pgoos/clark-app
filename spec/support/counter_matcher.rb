# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
RSpec::Matchers.define :change_counters do
  chain(:with_method) do |method_name|
    @method_name = method_name
  end

  chain(:from) do |state|
    state.each do |klass, counter|
      previous_state[klass] = counter
    end
  end

  chain(:to) do |state|
    state.each do |klass, counter|
      new_state[klass] = counter
    end
  end

  chain(:to_zeros) do
    @new_state = previous_state.keys.map { |klass| [klass, 0] }
  end

  match do |actual|
    return false unless match_counters(:before_change, previous_state)
    actual.call
    return false unless match_counters(:after_change, new_state)
    true
  end

  def previous_state
    @previous_state ||= {}
  end

  def new_state
    @new_state ||= {}
  end

  def method_name
    @method_name || :count
  end

  def errors
    @errors ||= {before_change: {}, after_change: {}}
  end

  def errors?
    errors[:before_change].empty? && errors[:after_change].empty?
  end

  def match_counters(namespace, state)
    state.each do |klass, previous_counter|
      new_counter = klass.public_send(:count)
      errors[namespace][klass] = [previous_counter, new_counter] unless previous_counter == new_counter
    end
    errors?
  end

  failure_message do
    message = +"expected"
    errors.each do |ns, ns_errors|
      next if ns_errors.empty?
      message << " #{ns}: "
      tokens = ns_errors.map do |klass, counters|
        "#{klass} to have #{counters[0]} record(s) but got #{counters[1]}"
      end
      message << tokens.join(", ")
    end
    message
  end

  def supports_block_expectations?
    true
  end
end
# rubocop:enable Metrics/BlockLength
