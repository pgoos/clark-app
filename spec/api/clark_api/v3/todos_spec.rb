# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::V3::Todos, :integration do
  let!(:mandate) { create(:mandate, :accepted) }
  let(:user) { create(:user, mandate: mandate) }
  let(:category) { create(:category) }

  #NOTE: This is a very basic test since the Lifter resturning the recommendations is heavily tested
  #plus the entity unit test is also present

  context "exposes the category page" do


    it "should reject any non authenticated user" do
      json_get_v3 "/api/todos/next"
      expect(response.status).to eq(401)
    end

    context "number one recommendation present" do
      let!(:mandate) { create(:mandate, :accepted) }
      let!(:questionnaire) { create(:questionnaire) }
      let!(:category) { create(:category, questionnaire: questionnaire, priority: 10, name: "AB", life_aspect: "health") }
      let!(:recommendation) { create(:recommendation, mandate: mandate, category: category) }

      before do
        login_as(user, scope: :user)
        allow(mandate).to receive(:done_with_demandcheck?).and_return(true)
      end

      it "should return the number one recommendation with status ok" do
        json_get_v3 "/api/todos/next"
        expect(response.status).to eq(200)
        expect(response.body).not_to be_nil
      end
    end

    context "number one recommendation  not present" do
      let!(:mandate) { create(:mandate, :accepted) }

      before do
        login_as(user, scope: :user)
        allow(mandate).to receive(:done_with_demandcheck?).and_return(true)
      end

      it "should not return error code" do
        json_get_v3 "/api/todos/next"
        expect(response.status).to eq(200)
      end

      it "should return an empty response" do
        json_get_v3 "/api/todos/next"
        expect(response.body).to eq({}.to_s)
      end
    end
  end
end
