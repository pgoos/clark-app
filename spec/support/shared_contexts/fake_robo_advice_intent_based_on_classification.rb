# frozen_string_literal: true

RSpec.shared_context "fake robo advice intent based on classification" do
  before do
    allow_any_instance_of(Domain::Intents::RoboAdvisorAdvices)
      .to receive(:advice_text_based_on_classification) { |_, _, attr| attr[:content] }
  end
end
