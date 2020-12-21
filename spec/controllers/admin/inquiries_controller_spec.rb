# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::InquiriesController, :integration, type: :controller do
  let(:role)  { create(:role, permissions: Permission.where(controller: "admin/inquiries")) }
  let(:admin) { create(:admin, role: role) }
  let(:inquiry)          { create :inquiry }
  let(:inquiry_category) { create :inquiry_category, inquiry: inquiry }

  let(:params) do
    {
      locale:                   :de,
      id:                       inquiry.id,
      inquiry_cancel_selection: {inquiry_category.id => "inquiry_is_duplicated"}
    }
  end

  before { sign_in(admin) }

  describe "POST cancel_with_options" do
    before do
      request.env["HTTP_REFERER"] = admin_inquiries_path
      post :cancel_with_options, params: params
    end

    it "cancels an inquiry" do
      expect(inquiry.reload).to be_canceled
      expect(inquiry_category.reload).to be_inquiry_is_duplicated
      expect(response).to redirect_to admin_inquiries_path
      expect(flash[:notice]).to eq "Abbruch von Anfragekategorien erfolgreich."
    end
  end

  describe "GET index" do
    before { get :index, params: {locale: :de, order: "subcompany.name_desc"} }

    it "responds with success" do
      expect(response.status).to eq 200
    end
  end

  describe "contact_insurance" do
    let(:contacts_lifter) { instance_double(Domain::Inquiries::InitialContacts) }

    before do
      allow(contacts_lifter).to receive(:send_insurance_requests)
    end

    it "contacts insurers" do
      expect_any_instance_of(Domain::Inquiries::InitialContacts)
        .to receive(:send_insurance_requests).with([inquiry])
      patch :contact_insurance, params: {locale: :de, id: inquiry.id}
    end
  end

  describe "POST /create" do
    let(:mandate) { create(:mandate) }
    let(:company) { create(:company) }
    let(:subcompany) { create(:subcompany, company: company) }
    let(:category) { create(:category) }

    before { post :create, params: {locale: :de, inquiry: params, mandate_id: mandate.id} }

    context "with valid attributes" do
      let(:inquiry) { Inquiry.last }
      let(:params) do
        {
          company_id: company.id,
          subcompany_id: subcompany.id,
          inquiry_categories_attributes: {category_id: category.id}
        }
      end

      it { expect(inquiry.company).to eq company }
      it { expect(inquiry.subcompany).to eq subcompany }
      it { is_expected.to set_flash[:notice] }
      it { is_expected.to redirect_to(admin_inquiry_path(Inquiry.last)) }
    end

    context "with invalid attributes" do
      let(:params) do
        {
          inquiry_categories_attributes: {category_id: 0}
        }
      end

      it { is_expected.to set_flash[:alert] }
      it { is_expected.to render_template("new") }
    end
  end

  describe "#document_upload" do
    let(:document) do
      Rack::Test::UploadedFile.new(Rails.root.join("spec", "support", "assets", "mandate.pdf"))
    end

    context "with invalid params" do
      before do
        post :document_upload, params: {id: inquiry.id, locale: :de, inquiry: invalid_params}
      end

      context "when document does not exist" do
        let(:invalid_params) do
          {
            document: nil,
            inquiry_category_id: inquiry_category.id
          }
        end

        it do
          expect(subject).to set_flash[:alert]
          expect(subject).to redirect_to(admin_inquiry_path(inquiry))
        end
      end

      context "when inquiry_category does not exist" do
        let(:invalid_params) do
          {
            document: document,
            inquiry_category_id: 0
          }
        end

        it do
          expect(subject).to set_flash[:alert]
          expect(subject).to redirect_to(admin_inquiry_path(inquiry))
        end
      end
    end

    context "with valid params" do
      let(:valid_params) do
        {
          document: document,
          inquiry_category_id: inquiry_category.id
        }
      end

      let(:action_dispatch_document) do
        ActionDispatch::Http::UploadedFile.new
      end

      context "with validations" do
        before do
          post :document_upload, params: {id: inquiry.id, locale: :de, inquiry: valid_params}
        end

        it do
          expect(subject).to set_flash[:notice]
          expect(subject).to redirect_to(admin_inquiry_path(inquiry))
        end
      end

      context "when calling the lifter" do
        let(:lifter_double) { instance_double(Domain::OCR::RecognitionCreation) }

        it "should call the lifter to create the document" do
          expect(Domain::OCR::RecognitionCreation).to \
            receive(:new).with(an_instance_of(ActionDispatch::Http::UploadedFile), inquiry_category)
                         .and_return(lifter_double)
          expect(lifter_double).to receive(:create_recognition)

          post :document_upload, params: {id: inquiry.id, locale: :de, inquiry: valid_params}
        end
      end
    end
  end
end
