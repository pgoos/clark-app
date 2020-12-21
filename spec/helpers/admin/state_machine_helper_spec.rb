# frozen_string_literal: true

require "rails_helper"

class ClassWithStates
  state_machine :state, initial: :created do
    state :in_progress
    state :completed
  end
end

RSpec.describe Admin::StateMachineHelper, type: :helper do
  def states_locale(locale)
    allow(Settings).to(
      receive_message_chain("ops_ui.state_machine.translation_key").and_return(locale)
    )
  end

  describe "#state_options_for" do
    RSpec.shared_context "localized_state_options_for" do |locale|
      let(:translated_options_wo_current) do
        translated_options[1..-1]
      end

      before { states_locale(locale) }

      let(:call) do
        helper.state_options_for(
          ClassWithStates.new, exclude_instance_state: exclude_instance_state
        )
      end

      context "when exclude_instance_state enabled" do
        let(:exclude_instance_state) { true }

        it "returns options without current" do
          expect(call).to match_array(translated_options_wo_current)
        end
      end

      context "when exclude_instance_state disabled" do
        let(:exclude_instance_state) { false }

        it "returns options" do
          expect(call).to match_array(translated_options)
        end
      end
    end

    context "when locale is 'en'" do
      let(:translated_options) do
        [
          %w[created created],
          ["in progress", "in_progress"],
          %w[completed completed]
        ]
      end

      include_context "localized_state_options_for", "en"
    end

    context "when locale is 'de'" do
      let(:translated_options) do
        [
          %w[erstellt created],
          %w[abgeschlossen completed],
          ["in Bearbeitung", "in_progress"]
        ]
      end

      include_context "localized_state_options_for", "de"
    end
  end

  describe "#translate_current_state" do
    let(:call) do
      helper.translate_current_state(ClassWithStates.new)
    end

    context "when locale is 'en'" do
      before { states_locale("en") }

      it "returns current state" do
        expect(call).to eq("created")
      end
    end

    context "when locale is 'de'" do
      before { states_locale("de") }

      it "returns current state" do
        expect(call).to eq("erstellt")
      end
    end
  end
end
