# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Owners::Zvo, :integration do
  it_behaves_like "an owner", Domain::Owners::ZVO_IDENT
end
