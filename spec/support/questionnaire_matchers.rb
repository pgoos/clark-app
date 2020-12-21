module QuestionnaireMatchers
  #
  # Helper Methods
  #

  # question_context creates a context with the given question identifier.
  # It also creates a question with the given identifier on the questionnaire object

  def question_context(question_identifier, &example_group_block)
    example_group_class = context question_identifier do
      before(:each) { questionnaire_response.questionnaire.questions << create(:custom_question, question_identifier: question_identifier) }
    end

    example_group_class.class_eval(&example_group_block)
  end

  def answered_with(answer_text, mandate_options={}, &example_group_block)
    context_title = "answered with \"#{answer_text}\""

    if mandate_options.present?
      context_title += " (with #{mandate_options.map{|k,v| "#{k}=#{v}"}.join(', ')})"
    end

    example_group_class = context(context_title) do
      before(:each) do

        if mandate_options.present?
          builder.mandate.assign_attributes(mandate_options)
        end

        questionnaire_response.create_answer!(questionnaire.questions.first, ValueTypes::Text.new(answer_text))
        builder.analyze_questionnaire
      end
    end

    example_group_class.class_eval(&example_group_block)
  end

  RSpec::Matchers.define :recommend do |*expected|
    match do |actual|
      (actual.recommended ^ expected.to_set).empty?
    end

    failure_message do |actual|
      "expected to recommend: #{expected.inspect}
                  got: #{actual.recommended.to_a.inspect}
           additional: #{(actual.recommended.to_a - expected).inspect}
              missing: #{(expected - actual.recommended.to_a).inspect}"
    end
  end

  RSpec::Matchers.define :recommend_nothing do
    match do |actual|
      actual.recommended.empty?
    end
  end

  RSpec::Matchers.define :emphasize do |*expected|
    match do |actual|
      (actual.important ^ expected.to_set).empty?
    end

    failure_message do |actual|
      "expected to recommend as important: #{expected.inspect}
                               got: #{actual.important.to_a.inspect}
                        additional: #{(actual.important.to_a - expected).inspect}
                           missing: #{(expected - actual.important.to_a).inspect}"
    end
  end

  RSpec::Matchers.define :emphasize_nothing do
    match do |actual|
      actual.important.empty?
    end
  end
end


