# frozen_string_literal: true

require "rails_helper"

describe "rake one_time_messages:sales_activation", type: :task do
  let(:mandate_id) { 1 }
  let(:fixture) { Rails.root.join("lib", "tasks", "one_time_messages", "sales_activation_mandate_ids.json") }

  before do
    allow(File).to receive(:read).with(fixture).and_return({ids: [mandate_id]}.to_json)
  end

  it "enqueues SalesActivationMessageJob with mandate_id" do
    expect { task.invoke }.to have_enqueued_job(SalesActivationMessageJob).with(mandate_id)
  end
end

describe "rake one_time_messages:sales_activation_feb", type: :task do
  let(:mandate_id) { 1 }
  let(:mandate_ids) { CSV.parse("mandate_id\n#{mandate_id}", headers: true) }
  let(:fixture) { Rails.root.join("lib", "tasks", "one_time_messages", "sales_activation_feb_mandate_ids.csv") }

  it "ensures the fixture files exists" do
    expect(File.exist?(fixture)).to be true
    expect(CSV.read(fixture, headers: true)[0]["mandate_id"]).not_to be_empty
  end

  it "enqueues SalesActivationMessageFebJob with mandate_id" do
    expect(CSV).to receive(:foreach).with(fixture, headers: true).and_return(mandate_ids)
    expect do
      task.invoke
    end.to have_enqueued_job(SalesActivationMessageFebJob)
      .with(mandate_id.to_s, "Group2a")
      .on_queue("sales_activation_messages")
  end
end

describe "rake one_time_messages:sales_activation_feb_group1", type: :task do
  let(:mandate_id) { 1 }
  let(:mandate_ids) { CSV.parse("mandate_id\n#{mandate_id}", headers: true) }
  let(:fixture) { Rails.root.join("lib", "tasks", "one_time_messages", "sales_activation_feb_group1_mandate_ids.csv") }

  it "ensures the fixture files exists" do
    expect(File.exist?(fixture)).to be true
    expect(CSV.read(fixture, headers: true)[0]["mandate_id"]).not_to be_empty
  end

  it "enqueues SalesActivationMessageFebJob with mandate_id" do
    expect(CSV).to receive(:foreach).with(fixture, headers: true).and_return(mandate_ids)
    expect do
      task.invoke
    end.to have_enqueued_job(SalesActivationMessageFebJob)
      .with(mandate_id.to_s, "Group1")
      .on_queue("sales_activation_messages")
  end
end

describe "rake one_time_messages:inactive_customers", type: :task do
  let(:fixture) { Rails.root.join("lib", "tasks", "one_time_messages", "inactive_customer_mandate_ids.csv") }
  let(:mailer) { double(:mailer, deliver_now: nil) }

  it "ensures the fixture files exists" do
    expect(File.exist?(fixture)).to be true
    expect(CSV.read(fixture, headers: true)[0]["mandate_id"]).not_to be_empty
  end

  context "when mandate exists in DB" do
    let!(:existing_mandate) { create(:mandate) }
    let(:mandate_ids) { CSV.parse("mandate_id\n#{existing_mandate.id}", headers: true) }

    before do
      allow(MandateMailer).to \
        receive(:inactive_customer).with(existing_mandate).and_return mailer
    end

    it "should call MandateMail service and enqueued notification" do
      expect(CSV).to receive(:foreach).with(fixture, headers: true).and_return(mandate_ids)
      expect(mailer).to receive(:deliver_now)
      expect { task.invoke }.to \
        have_enqueued_job(PushNotificationJob).with(existing_mandate.id, "inactive_customer")
    end
  end

  context "when mandate doesn\'t exists in DB" do
    let(:non_existing_mandate) { 13 }
    let(:mandate_ids) { CSV.parse("mandate_id\n#{non_existing_mandate}", headers: true) }

    before do
      allow(MandateMailer).to \
        receive(:inactive_customer).with(non_existing_mandate).and_return mailer
    end

    it "shouldn\'t call MandateMail service" do
      expect(CSV).to receive(:foreach).with(fixture, headers: true).and_return(mandate_ids)
      expect(mailer).not_to receive(:deliver_now)
      task.invoke
    end
  end
end
