# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Messenger::TransactionalMessenger::RecommendationMessenger do
  let!(:admin) { create(:admin) }
  let(:transactional_messenger) { OutboundChannels::Messenger::TransactionalMessenger }
  let(:message) { double("message") }

  let(:mandate) { create(:mandate) }

  context "if questionnaire present" do
    let!(:questionnaire) { create(:questionnaire) }

    let!(:category) { create(:category, life_aspect: "health", questionnaire: questionnaire) }

    let(:options) {
      {
        name:     mandate.first_name,
        category: category.name,
        cta_url:  "questionnaire/#{questionnaire.identifier}"
      }
    }
    it "sends number one recommendation reminder 1 days" do
      expect(transactional_messenger).to receive(:new)
        .with(mandate, "number_one_recommendation_1_day", options, kind_of(Config::Options))
        .and_return(message)
      expect(message).to receive(:send_message)

      transactional_messenger.number_1_recommendation_day1(mandate, category)
    end

    it "sends number one recommendation reminder 2 days" do
      expect(transactional_messenger).to receive(:new)
        .with(mandate, "number_one_recommendation_2_day", options, kind_of(Config::Options))
        .and_return(message)
      expect(message).to receive(:send_message)

      transactional_messenger.number_1_recommendation_day2(mandate, category)
    end

    it "sends number one recommendation reminder 5 days" do
      expect(transactional_messenger).to receive(:new)
        .with(mandate, "number_one_recommendation_5_day", options, kind_of(Config::Options))
        .and_return(message)
      expect(message).to receive(:send_message)

      transactional_messenger.number_1_recommendation_day5(mandate, category)
    end
  end

  context "if questionnaire not present" do
    let!(:category) { create(:category, life_aspect: "health") }
    let(:options) {
      {
        name:     mandate.first_name,
        category: category.name,
        cta_url:  "manager/categories/#{category.id}"
      }
    }

    it "sends number one recommendation reminder 1 days" do
      expect(transactional_messenger).to receive(:new)
        .with(mandate, "number_one_recommendation_1_day", options, kind_of(Config::Options))
        .and_return(message)
      expect(message).to receive(:send_message)

      transactional_messenger.number_1_recommendation_day1(mandate, category)
    end
  end

end
