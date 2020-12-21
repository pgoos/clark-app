# frozen_string_literal: true

RSpec.shared_examples "an activatable model" do |initial_state=:active|
  def is_expected_to_move_from_to model, event, from_state, to_state
    model.state = from_state
    expect(model.send("#{event}_transition").from_name).to eq from_state
    expect(model.send("#{event}_transition").to_name).to eq to_state
  end

  let(:model) { build ActiveModel::Naming.singular(described_class) }

  it { expect(model.state.to_s).to eq(initial_state.to_s) }

  context "when state = active" do
    before { model.state = :active }

    it { expect(model).to be_active }
    it { is_expected_to_move_from_to(model, :deactivate, :active, :inactive) }
  end

  context "when state = inactive" do
    before { model.state = :inactive }

    it { expect(model).to be_inactive }
    it { is_expected_to_move_from_to(model, :activate, :inactive, :active) }
  end
end
