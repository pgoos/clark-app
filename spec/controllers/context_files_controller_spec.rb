# frozen_string_literal: true

require "rails_helper"

RSpec.describe ContextFilesController, :integration, type: :controller do
  describe "GET favicon" do
    it "responds with 200" do
      expect(response.status).to eq(200)
    end
  end
end
