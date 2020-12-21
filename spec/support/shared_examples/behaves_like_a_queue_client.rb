# frozen_string_literal: true

RSpec.shared_examples "queue_client" do
  before do
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new(env.to_s))
  end

  after do
    allow(Rails).to receive(:env).and_call_original
  end

  it "returns the right object" do
    expect(subject).to be_a_kind_of(expected_class)
  end
end
