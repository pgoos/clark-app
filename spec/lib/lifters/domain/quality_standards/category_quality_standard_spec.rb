# frozen_string_literal: true

require "rails_helper"
      
RSpec.describe Domain::ContentGeneration::ContentProvider do
  let(:some) { Domain::ContentGeneration::Some }
  let(:none) { Domain::ContentGeneration::None }

  context "retrieving content" do
    def retrieve(ident)
      described_class.quality_from_category(ident)
    end

    context "GKV" do
      let(:ident) { "3659e48a" }
      let(:content) { Category.find_by(ident: ident) }

      it "finds the content by ident for" do
        expect(retrieve(ident).process).to be_a(some)
      end
      
      it "fids none with invalid ident" do
        expect(retrieve("tomatoes").process).to be_a(none)
      end

      it "has a some with content" do
        expect(retrieve(ident).process.content).to eq(content)
      end
    end
  end
end
