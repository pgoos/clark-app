# frozen_string_literal: true

require "rails_helper"

RSpec.describe Statistics::User::InquiriesRepository, :integration do
  subject { described_class.new(mandate: mandate) }

  let(:user) do
    create(
      :user,
      last_sign_in_at: last_sign_in_at,
      current_sign_in_at: current_sign_in_at
    )
  end
  let(:mandate) { create(:mandate, user: user) }

  let(:now) { Time.zone.parse("2010-01-03 10:00:00") }
  let(:yesterday) { Time.zone.parse("2010-01-02 23:59:59") }
  let(:last_sign_in_at) { Time.zone.parse("2010-01-03 00:00:00") }
  let(:current_sign_in_at) { Time.zone.parse("2010-01-03 00:30:00") }
  let(:after_sign_in) { Time.zone.parse("2010-01-03 01:00:00") }

  let(:inquiry_category) do
    create(
      :inquiry_category,
      inquiry: inquiry
    )
  end

  let(:build_document) do
    create(
      :document,
      document_type: DocumentType.customer_upload,
      documentable: inquiry_category,
      updated_at: document_created_at
    )
  end

  let(:inquiry) do
    create(
      :inquiry,
      mandate: mandate,
      created_at: document_created_at
    )
  end

  before { Timecop.freeze(now) }

  after { Timecop.return }

  describe "#categories" do
    context "with inquiry document created in :today range" do
      let(:document_created_at) { after_sign_in }

      it "returns the offer" do
        build_document
        expect(subject.categories(period: :today)).to eq([inquiry_category])
      end
    end

    context "with inquiry document created before :today range" do
      let(:document_created_at) { yesterday }

      it "returns no inquiry" do
        build_document
        expect(subject.categories(period: :today)).to eq([])
      end
    end
  end
end
