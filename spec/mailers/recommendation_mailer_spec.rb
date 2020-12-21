# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecommendationMailer, :integration, type: :mailer do
  let!(:mandate) { create :mandate, user: user, state: :created }
  let(:user) { create :user, email: email, subscriber: true }
  let(:email) { "whitfielddiffie@gmail.com" }
  let!(:category) { create(:category) }
  let!(:recommendation) { create(:recommendation, mandate: mandate, category: category) }
  let(:documentable) { mandate }

  describe "#recommendataion_num_one_reccommendation_day_five" do
    let(:mail) { RecommendationMailer.num_one_reccommendation_day_five(mandate, recommendation) }
    let(:document_type) { DocumentType.num_one_reccommendation_day_five }

    include_examples "checks mail rendering"
    include_examples "tracks document and mandate in ahoy email"
    include_examples "does not send out an email if mandate belongs to the partner"
  end

  describe "#recommendataion_num_one_reccommendation_day_one" do
    let(:mail) { RecommendationMailer.num_one_reccommendation_day_one(mandate, recommendation) }
    let(:document_type) { DocumentType.num_one_reccommendation_day_one }

    include_examples "checks mail rendering"
    include_examples "tracks document and mandate in ahoy email"
    include_examples "does not send out an email if mandate belongs to the partner"
  end

  describe "#recommendataion_num_one_reccommendation_day_two" do
    let(:mail) { RecommendationMailer.num_one_reccommendation_day_two(mandate, recommendation) }
    let(:document_type) { DocumentType.num_one_reccommendation_day_two }

    include_examples "checks mail rendering"
    include_examples "tracks document and mandate in ahoy email"
    include_examples "does not send out an email if mandate belongs to the partner"
  end
end
