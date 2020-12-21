# frozen_string_literal: true

require "rails_helper"

RSpec.describe Documents::RequestReuploadJob do
  it { is_expected.to be_an(ActiveJob::Base) }
  it { expect(subject.job_id).to be_present }

  describe ".perform" do
    let(:consultant) { create(:admin) }
    let(:product) { create(:product_gkv) }
    let(:document) { create(:document, documentable: product, document_type: DocumentType.request_document_reupload) }
    let(:mailer) { double(ProductMailer) }

    before do
      allow(ProductMailer).to receive(:request_document_reupload)
        .with(document.documentable)
        .and_return(mailer)
      allow(mailer).to receive(:deliver_now)
    end

    context "with DocumentType request_document_reupload" do
      it "delivers request_document_reupload mail" do
        subject.perform(document.id, consultant.id)
        expect(mailer).to have_received(:deliver_now)
      end

      it "creates an interaction" do
        expect { subject.perform(document.id, consultant.id) }.to change { Interaction::Email.count }.by(1)
      end
    end

    context "with another DocumentType" do
      let(:document) { create(:document, documentable: product, document_type: DocumentType.customer_upload) }

      it "doesn't deliver request_document_reupload mail" do
        subject.perform(document.id, consultant.id)
        expect(mailer).not_to have_received(:deliver_now)
      end

      it "doesn't create any interaction" do
        expect { subject.perform(document.id, consultant.id) }.to change { Interaction::Email.count }.by(0)
      end
    end
  end
end
