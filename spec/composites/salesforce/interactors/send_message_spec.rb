# frozen_string_literal: true

require "rails_helper"
require "composites/salesforce/interactors/send_message"
require "composites/salesforce/repositories/customer_repository"
require "composites/salesforce/repositories/admin_repository"

RSpec.describe Salesforce::Interactors::SendMessage, :integration do
  subject { described_class.new(customer_repo: customer_repo, admin_repo: admin_repo) }

  let(:customer) { create(:mandate) }
  let(:admin) { create(:admin) }

  let(:customer_repo) do
    instance_double(
      Salesforce::Repositories::CustomerRepository,
      find: customer
    )
  end

  let(:admin_repo) do
    instance_double(
      Salesforce::Repositories::AdminRepository,
      bot: admin
    )
  end

  it "calls the find method in customer repository" do
    allow(::Domain::Messenger::Messages::Outgoing::Dispatch).to receive(:call)
    expect(customer_repo).to receive(:find).with(customer.id)
    subject.call(customer.id, "message", "cta_text", "cta_link", "")
  end

  it "is successful" do
    result = subject.call(customer.id, "message", "cta_text", "cta_link", "")
    expect(result).to be_successful
  end
end
