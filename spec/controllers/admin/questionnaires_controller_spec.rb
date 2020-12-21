# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::QuestionnairesController, :integration, type: :controller do
  let(:role)  { create(:role, permissions: Permission.where(controller: "admin/questionnaires")) }
  let(:admin) { create(:admin, role: role) }

  before { sign_in(admin) }

  describe "GET #index" do
    let!(:category) { create(:category) }
    let!(:questionnaire1) { create(:questionnaire, category: category) }
    let!(:questionnaire2) { create(:questionnaire, category: category) }

    before { category.update(questionnaire_id: questionnaire1.id) }

    context "without any filter param" do
      it "should return all questionnaires" do
        get :index, params: {locale: :de}
        expect(response).to have_http_status(:ok)
        expect(assigns(:questionnaires).map(&:id)).to include(questionnaire1.id, questionnaire2.id)
      end
    end

    context "active param is true" do
      it "should return only active questionnaires" do
        get :index, params: {locale: :de, active: true}
        expect(response).to have_http_status(:ok)
        expect(assigns(:questionnaires).map(&:id)).to eq([questionnaire1.id])
      end
    end

    context "active param is false" do
      it "should return only inactive questionnaires" do
        get :index, params: {locale: :de, active: false}
        expect(response).to have_http_status(:ok)
        expect(assigns(:questionnaires).map(&:id)).to eq([questionnaire2.id])
      end
    end
  end

  describe "PUT update" do
    let(:questionnaire) { create(:questionnaire, optional_appointment: false) }

    context "when properties are passed in" do
      let(:params) {
        {
          optional_appointment: true
        }
      }

      it "updates model" do
        put :update, params: { locale: :de, id: questionnaire.id, questionnaire: params }

        expect(questionnaire.reload.optional_appointment).to be_truthy
      end
    end
  end

  describe "PATCH typeform_questions_sync" do
    let(:questionnaire) { create :questionnaire }

    before { request.env["HTTP_REFERER"] = root_path }

    it "synchronizes typeform question" do
      expect_any_instance_of(TypeformService::TypeformSync)
        .to receive(:sync).with(no_args)
      patch :typeform_questions_sync, params: {locale: :de, id: questionnaire.id}
      expect(response).to redirect_to root_path
    end
  end
end
