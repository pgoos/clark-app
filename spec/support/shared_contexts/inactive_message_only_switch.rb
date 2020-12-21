# frozen_string_literal: true

RSpec.shared_context "inactive message only switch" do
  before do
    allow(Features).to receive(:active?).and_call_original
    allow(Features).to receive(:active?).with(Features::MESSAGE_ONLY).and_return(false)
  end
end
