# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Owners::Communikom, :integration do
  it_behaves_like "an owner", Domain::Owners::COMMUNIKOM_IDENT
end
