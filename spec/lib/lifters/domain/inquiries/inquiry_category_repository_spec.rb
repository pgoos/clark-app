# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Inquiries::InquiryCategoryRepository, :integration do
  let(:mandate) { create(:mandate, :accepted) }
  let(:revoked) { create(:mandate, :revoked) }
  let(:inquiry) { create(:inquiry, mandate: mandate) }
  let(:inquiry_revoked) { create(:inquiry, mandate: revoked) }
  let(:add_doc_and_retain_dismissed_value) do
    lambda do |inquiry_category, document_size=1|
      dismissed = inquiry_category.customer_documents_dismissed
      create_list(:document, document_size, document_type: DocumentType.customer_upload, documentable: inquiry_category)

      # we need to reestablish the dismissed state, since the document creation sets it to false
      return unless dismissed
      inquiry_category.reload
      inquiry_category.update!(customer_documents_dismissed: dismissed)
    end
  end

  it "should know the doc type" do
    expect(DocumentType.customer_upload).to be_a(DocumentType)
  end

  describe "#with_older_active_customer_uploads" do
    it "should load of accepted customers with upload in the states in_progress and cancelled not dismissed" do
      to_be_found = [
        create(:inquiry_category, inquiry: inquiry, state: :in_progress, customer_documents_dismissed: false),
        create(:inquiry_category, inquiry: inquiry, state: :cancelled, customer_documents_dismissed: false)
      ]

      not_to_be_found = [
        create(:inquiry_category, inquiry: inquiry, state: :completed, customer_documents_dismissed: false),
        create(:inquiry_category, inquiry: inquiry, state: :in_progress, customer_documents_dismissed: true),
        create(:inquiry_category, inquiry: inquiry_revoked, state: :in_progress, customer_documents_dismissed: false)
      ]
      (to_be_found + not_to_be_found).each(&add_doc_and_retain_dismissed_value)

      create(:inquiry_category, inquiry: inquiry, state: :cancelled, customer_documents_dismissed: false)

      results = subject.with_older_active_customer_uploads(states: %i[in_progress cancelled])

      expect(results).to contain_exactly(*to_be_found)
    end

    it "should load of accepted customers with upload in the state completed not dismissed" do
      to_be_found = [
        create(:inquiry_category, inquiry: inquiry, state: :completed, customer_documents_dismissed: false),
        create(:inquiry_category, inquiry: inquiry, state: :completed, customer_documents_dismissed: false)
      ]

      not_to_be_found = [
        create(:inquiry_category, inquiry: inquiry, state: :completed, customer_documents_dismissed: true),
        create(:inquiry_category, inquiry: inquiry, state: :in_progress, customer_documents_dismissed: false),
        create(:inquiry_category, inquiry: inquiry, state: :cancelled, customer_documents_dismissed: false),
        create(:inquiry_category, inquiry: inquiry_revoked, state: :completed, customer_documents_dismissed: false)
      ]
      (to_be_found + not_to_be_found).each(&add_doc_and_retain_dismissed_value)

      create(:inquiry_category, inquiry: inquiry, state: :completed, customer_documents_dismissed: false)

      results = subject.with_older_active_customer_uploads(states: :completed)

      expect(results).to contain_exactly(*to_be_found)
    end

    it "order by oldest created document" do
      to_be_found = [
        create(:inquiry_category, inquiry: inquiry, state: :completed, customer_documents_dismissed: false),
        create(:inquiry_category, inquiry: inquiry, state: :completed, customer_documents_dismissed: false)
      ]

      to_be_found.each do |inquiry_category|
        add_doc_and_retain_dismissed_value.call(inquiry_category, 2)
      end
      to_be_found[1].documents[1].update!(created_at: 1.week.ago)

      create(:inquiry_category, inquiry: inquiry, state: :completed, customer_documents_dismissed: false)

      results = subject.with_older_active_customer_uploads(states: :completed)

      expect(results[0]).to eq(to_be_found[1])
      expect(results[1]).to eq(to_be_found[0])
    end
  end

  describe "#with_newer_active_customer_uploads" do
    it "order by oldest created document" do
      to_be_found = [
        create(:inquiry_category, inquiry: inquiry, state: :completed, customer_documents_dismissed: false),
        create(:inquiry_category, inquiry: inquiry, state: :completed, customer_documents_dismissed: false)
      ]

      to_be_found.each do |inquiry_category|
        add_doc_and_retain_dismissed_value.call(inquiry_category, 2)
      end
      to_be_found[1].documents[0].update!(created_at: 1.week.ago)

      create(:inquiry_category, inquiry: inquiry, state: :completed, customer_documents_dismissed: false)

      results = subject.with_older_active_customer_uploads(states: :completed)

      expect(results[0]).to eq(to_be_found[1])
      expect(results[1]).to eq(to_be_found[0])
    end
  end

  describe "#older_than" do
    let(:ten_weeks_ago) { 10.weeks.ago.beginning_of_day }
    let(:more_than_ten_weeks) { ten_weeks_ago.advance(minutes: -5) }
    let(:now) { Time.zone.now }

    before do
      Timecop.freeze(now)
    end

    after do
      Timecop.return
    end

    it "should return all open inquiry categories older than a given date" do
      Timecop.travel(more_than_ten_weeks)
      to_be_found = [
        create(:inquiry_category, inquiry: inquiry, state: :in_progress),
        create(:inquiry_category, inquiry: inquiry_revoked, state: :in_progress)
      ]

      Timecop.travel(ten_weeks_ago)
      create(:inquiry_category, inquiry: inquiry, state: :in_progress)
      create(:inquiry_category, inquiry: inquiry_revoked, state: :in_progress)

      Timecop.travel(now.advance(days: -1))
      expect(subject.older_than(time: ten_weeks_ago)).to contain_exactly(*to_be_found)
    end
  end
end
