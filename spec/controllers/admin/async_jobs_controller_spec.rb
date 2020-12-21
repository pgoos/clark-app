# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::AsyncJobsController, :integration, type: :controller do
  let(:mandate) { create(:mandate, user: create(:user)) }
  let(:role)    { create(:role, permissions: Permission.where(controller: "admin/async_jobs")) }
  let(:admin)   { create(:admin, role: role) }
  let(:category) { create(:category_phv) }
  let(:opportunity) { create(:opportunity, category: category) }
  let(:now) { Time.zone.now }

  before do
    login_admin(admin)
    Timecop.freeze(now)
  end

  after do
    Timecop.return
  end

  it "should have the status of 'gone' if the job cannot be found" do
    get :status, params: {locale: :de, job: "arbitrary_job_id", format: :json}
    expect(json_response.status).to eq("gone")
  end

  context "job exists" do
    let(:job_id) { "4267fb14-0acb-4e68-a7db-98eea9fd7b#{rand(100).floor}" }
    let(:job) { double("job", job_id: job_id, last_error: "") }

    before do
      allow(Delayed::Job)
        .to receive(:find_by)
        .with(job_id: job_id)
        .and_return(job)
    end

    it "should have the status of 'pending' if the job is found and healthy" do
      get :status, params: {locale: :de, job: job_id, format: :json}
      expect(json_response.status).to eq("pending")
    end

    it "should have the status of 'failed' with an error if the job is found and failed" do
      expected_error_text = "Some error text #{rand(100)}!"
      allow(job).to receive(:last_error).and_return(expected_error_text)

      get :status, params: {locale: :de, job: job_id, format: :json}

      expect(json_response.status).to eq("failed")
      expect(json_response.error).to eq(expected_error_text)
    end
  end
end
