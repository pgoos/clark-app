# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Ocr::OcrRecognitionsController, :integration do
  let(:roles) { create(:role, permissions: Permission.where(controller: "admin/ocr/ocr_recognitions")) }
  let(:admin) { create(:admin, role: roles) }

  before { login_admin(admin) }

  describe "POST /temporary_token" do
    let(:temporary_token_double) { instance_double(Lifters::OCR::TemporaryToken) }

    it "gets a temporary token" do
      expect(Lifters::OCR::TemporaryToken).to receive(:new).and_return(temporary_token_double)
      expect(temporary_token_double).to receive(:generate).with(admin)
      post :temporary_token, params: {locale: I18n.locale}
    end
  end

  describe "POST /" do
    it "gets a temporary token" do
      expect(CreateRecognitionWithFileJob).to receive(:perform_later)
      post :create, params: {locale: I18n.locale, file_name: "new_policy.pdf"}
    end
  end

  describe "DELETE /:id" do
    let(:ocr_recognition) { create(:ocr_recognition, :with_product_validation_succeded)}
    let(:subject) { delete :destroy, params: {locale: I18n.locale, id: ocr_recognition.id} }

    before { OCR::BIProjection.new(recognition: ocr_recognition).save }

    describe "When success" do
      it "does destroy a certain ocr_recognition record" do
        expect { subject }.to change {
          OCR::Recognition.where(id: ocr_recognition.id).exists?
        }.from(true).to(false)
      end

      it "does redirect with success notice" do
        expect { subject }.to change{flash[:notice]}
        expect(flash[:notice]).to eq(I18n.t("success"))
      end
    end

    describe "When failed" do
      let(:subject) {delete :destroy, params: {locale: I18n.locale, id: -1}}
      it "does NOT destroy any ocr_recognition record" do
        expect { subject }.not_to change {
          OCR::Recognition.where(id: ocr_recognition.id).exists?
        }
      end

      it "does redirect with generic_error alert" do
        expect { subject }.to change{flash[:alert]}
        expect(flash[:alert]).to eq(I18n.t("error.generic_error"))
      end
    end

    it "does redirect to admin_work_items_path with anchor pending_ocr_recognitions" do
      expect(subject).to redirect_to(controller: '/admin/work_items',
                                     anchor: 'pending_ocr_recognitions',
                                     action: :show)
    end
  end
end
