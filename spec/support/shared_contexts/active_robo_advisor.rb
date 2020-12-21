# frozen_string_literal: true

RSpec.shared_context "active robo advisor" do
  before do
    allow(Features).to receive(:active?).and_call_original
    allow(Features).to receive(:active?).with(Features::ROBO_ADVISOR).and_return(true)
  end
end
