# frozen_string_literal: true

RSpec::Matchers.define :expose do |attribute_name|
  match do |endpoint_class|
    @endpoint_class = endpoint_class
    object_responds_to?(attribute_name)
    return false unless @object_responds_to
    render_actual_value(attribute_name)
    init_expected_value(attribute_name)

    # actual matching:
    matches_nil ^
      (!@actual_value.nil? &&
      @actual_value == @expected_value &&
      @actual_value.is_a?(@type))
  end

  match_when_negated do |endpoint_class|
    @endpoint_class = endpoint_class
    object_responds_to?(attribute_name)
    return true unless @object_responds_to
    raise "object is missing!" if @object.nil?
    render_actual_value(attribute_name)
    @actual_value.nil? && !matches_nil
  end

  chain :of do |object|
    @object = object
  end

  chain :as do |type|
    @type = type
  end

  chain :with_value do |expected_value|
    @expected_value = expected_value
  end

  chain :with_nil_value do
    @expect_nil = true
  end

  chain :use_root_key do |root_key|
    @key_name = root_key.to_s
  end

  failure_message do |actual|
    return "The injected object of class #{@object.class} does not respond to the method ':#{attribute_name}'! Please provide the expected value by using .with_value(your_value)!" unless @object_responds_to
    return "The key #{@key_name} could not be found in the result: #{@subject}." if @json.nil?
    return "expected that #{actual} exposes the #{attribute_name} of #{@object.class} as nil, but was '#{@actual_value}:#{@actual_value.class}'" if @expect_nil
    "expected that #{actual} exposes the #{attribute_name} #{@expected_value} of #{@object.class} as #{@type}, but was #{@actual_value}:#{@actual_value.class}"
  end

  failure_message_when_negated do |actual|
    "expected not to expose #{attribute_name}, but found #{attribute_name}: #{@actual_value}!"
  end

  private

  def render_actual_value(attribute_name)
    @key_name ||= @endpoint_class.name.demodulize.underscore
    @json = if subject_instance.is_a?(Hash)
              subject_instance[@key_name].as_json
            else
              subject_instance.as_json
            end

    @actual_value = @json[attribute_name]
  end

  def init_expected_value(attribute_name)
    @expected_value ||= @object.send(attribute_name) unless @expect_nil
  end

  def subject_instance
    @subject ||= @endpoint_class.represent(@object)
  end

  def object_responds_to?(attribute_name)
    @object_responds_to = @object.respond_to?(attribute_name) ||
      @expect_nil ||
      !@expected_value.nil?
  end

  def matches_nil
    @actual_value.nil? && @expect_nil
  end
end
