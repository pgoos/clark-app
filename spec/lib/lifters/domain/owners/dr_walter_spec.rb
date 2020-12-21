# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Owners::DrWalter, :integration do
  it_behaves_like "an owner", Domain::Owners::DR_WALTER_IDENT
end
