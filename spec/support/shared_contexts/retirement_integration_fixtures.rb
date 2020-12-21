# frozen_string_literal: true

RSpec.shared_context "retirement integration fixtures" do
  before do
    Core::MainSeeder.load_retirement_users_seeds
  end
end
