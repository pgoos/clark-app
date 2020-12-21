# frozen_string_literal: true

require "rails_helper"

describe Qualitypool::TransferJobsRepository, :integration do
  def create_job(attrs)
    create(:delayed_job, attrs.merge(queue: "qualitypool_transfer"))
  end

  def find_job(response, job)
    response.find { |j| j[:job_id] == job.id.to_s }
  end

  describe "#all" do
    let!(:failed_job) { create_job(failed_at: Time.zone.now, attempts: 2, last_error: "error") }
    let!(:working_job) { create_job(locked_at: Time.zone.now) }
    let!(:pending_job) { create_job(attempts: 0) }
    let(:product) { create(:product) }
    let!(:job_with_product) { create_job(delayed_reference: product) }
    let(:runs) { {runs: [{"errors" => %w[error1]}]} }
    let!(:job_with_runs) { create_job(metadata: runs) }

    it "returns the correct jobs" do
      response = described_class.all

      job = find_job(response, failed_job)
      expect(job[:failed]).to eq true
      expect(job[:with_error]).to eq true
      expect(job[:working]).to eq false
      expect(job[:pending]).to eq false
      expect(job[:product_id]).to eq nil
      expect(job[:runs]).to eq []

      job = find_job(response, working_job)
      expect(job[:working]).to eq true
      expect(job[:with_error]).to eq false

      job = find_job(response, pending_job)
      expect(job[:pending]).to eq true

      job = find_job(response, job_with_product)
      expect(job[:product_id]).to eq product.id

      job = find_job(response, job_with_product)
      expect(job[:product_id]).to eq product.id

      job = find_job(response, job_with_runs)
      expect(job[:runs]).to eq runs[:runs]
    end
  end
end
