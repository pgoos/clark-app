# frozen_string_literal: true

require "rails_helper"

describe SendNewlyAddedInquiriesJob, type: :job do
  it "exits if mandate is not found" do
    expect(subject.perform(1)).to be_nil
  end

  it "runs Domain::Inquiries::SendNewlyAdded if mandate exists" do
    mandate = create(:mandate)
    expect_any_instance_of(Domain::Inquiries::SendNewlyAdded).to receive(:call).with(mandate)

    subject.perform(mandate.id)
  end
end
