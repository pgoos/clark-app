# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::V3::CategoryPages, :integration do
  subject { json_get_v3 "/api/category_pages/#{category.id}" }

  let(:category) { create(:category) }

  context "exposes the category page" do
    let(:expected_answer) do
      { content: "something" }
    end

    it "should reject any non authenticated user" do
      subject
      expect(response.status).to eq(200)
    end

    it "calls Domain::ContentGeneration::ContentProvider" do
      expect(Domain::ContentGeneration::ContentProvider).to receive(:page_from_category).with(category.ident).once
                                                                                        .and_return(expected_answer)

      subject
    end

    context "details_from_db setting is set to true" do
      before do
        allow(Settings).to receive_message_chain(:clark_api, :category_pages, :details_from_db).and_return(true)
      end

      it "calls ClarkAPI::V3::Entities::CategoryPage" do
        expect(ClarkAPI::V3::Entities::CategoryPage).to receive(:represent).with(category).once
                                                                           .and_return(expected_answer)

        subject
      end
    end
  end
end
