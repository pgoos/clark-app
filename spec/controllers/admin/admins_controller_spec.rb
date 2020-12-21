# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::AdminsController, :integration, type: :controller do
  let(:role_name) { "Role Name" }
  let(:admin) { create(:admin, role: role) }
  let(:role)  do
    create(
      :role,
      permissions: Permission.where(controller: "admin/admins"),
      name: role_name
    )
  end

  let(:mock_role_change_validator) do
    allow_any_instance_of(Domain::Admins::ValidateRoleChange).to(
      receive(:valid?).and_return(validation_passed)
    )

    return if validation_passed

    allow_any_instance_of(Admin).to(
      receive(:errors).and_return([{}])
    )
  end

  before do
    I18n.locale = :de
    sign_in(admin)
  end

  describe "GET /" do
    context "when there is a deactivated admin" do
      let!(:deactivated_admin) { create(:admin, state: "inactive") }

      before { get :index, params: {locale: I18n.locale} }

      context "when admin is a super admin" do
        let(:role_name) { "Super Admin" }

        it do
          expect(assigns[:admins]).to match_array([admin, deactivated_admin])
        end
      end

      context "when admin isn't a super admin" do
        it { expect(assigns[:admins]).to eq([admin]) }
      end
    end
  end

  describe "PATCH /activate" do
    let(:consultant) { create :gkv_consultants_admin, state: :inactive }
    let(:logger) { double.as_null_object }

    before do
      allow(Rails).to receive(:logger).and_return(logger)
      allow(logger).to receive(:info)

      patch :activate, params: {locale: I18n.locale, id: consultant.id}
    end

    it { expect(consultant.reload.state).to eq "active" }
    it do
      message = "Consultant #{consultant.id} was set to active (admin_management)"
      expect(logger).to have_received(:info).with(message)
    end
    it { is_expected.to redirect_to(admin_admin_path) }
    it { is_expected.to use_after_action(:log_event) }
    it { is_expected.to set_flash[:notice] }
  end

  describe "PATCH /deactivate" do
    let(:consultant) { create :gkv_consultants_admin }
    let(:logger) { double.as_null_object }

    before do
      allow(Rails).to receive(:logger).and_return(logger)
      allow(logger).to receive(:info)

      patch :deactivate, params: {locale: I18n.locale, id: consultant.id}
    end

    it { expect(consultant.reload.state).to eq "inactive" }
    it do
      message = "Consultant #{consultant.id} was set to inactive (admin_management)"
      expect(logger).to have_received(:info).with(message)
    end
    it { is_expected.to redirect_to(admin_admin_path) }
    it { is_expected.to use_before_action(:require_foreign_account) }
    it { is_expected.to use_after_action(:log_event) }
    it { is_expected.to set_flash[:notice] }
  end

  describe "POST /create" do
    let(:params) { build(:admin) }
    let(:password_params) do
      {password: Settings.seeds.default_password, password_confirmation: Settings.seeds.default_password}
    end
    let(:logger) { n_double("logger").as_null_object }

    before do
      allow(Rails).to receive(:logger).and_return(logger)
      allow(logger).to receive(:info)

      post(
        :create,
        params: {
          locale: I18n.locale,
          admin: params.attributes.merge(password_params)
        }
      )
    end

    it do
      message = "Consultant #{params.first_name} is being created (admin_management)"
      expect(logger).to have_received(:info).with(message)
    end
    it { expect(Admin.find_by(email: params[:email]).password_expires_at).not_to be_nil }
  end

  describe "POST /create with role assignment" do
    let(:admin_email) { "affected_admin@example.com" }

    let(:admin_params) do
      build(:admin).attributes.merge(
        password: Settings.seeds.default_password,
        password_confirmation: Settings.seeds.default_password
      )
    end

    let(:created_admin) { Admin.find_by(email: admin_params["email"]) }

    let(:call) do
      post(
        :create,
        params: {
          locale: I18n.locale,
          admin: admin_params
        }
      )
    end

    before { mock_role_change_validator }

    context "when role change validation passes" do
      let(:validation_passed) { true }

      it "creates an admin" do
        call
        expect(response.status).to eq(302)
        expect(created_admin).not_to be_nil
      end
    end

    context "with role change validation fails" do
      let(:validation_passed) { false }

      it "doesn't create an admin" do
        call
        expect(response.status).to eq(200)
        expect(response).to render_template(:new)
        expect(created_admin).to be_nil
      end
    end
  end

  describe "PATCH /update" do
    let!(:other_admin) { create(:admin) }
    let!(:other_role) { create(:role) }
    let(:affected_admin) { other_admin }

    let(:call) do
      patch(
        :update,
        params: {
          locale: I18n.locale,
          id: affected_admin.id,
          admin: admin_params
        }
      )
    end

    context "when password is going to be changed" do
      let(:new_password) { Settings.seeds.default_password + rand(10_000).to_s }
      let(:admin_params) do
        {
          password: new_password,
          password_confirmation: new_password
        }
      end

      context "when admin changes their own account" do
        let(:affected_admin) { admin }

        it "doesn't require the password to be changed" do
          call
          expect(affected_admin.reload.password_changed_at).not_to be_nil
        end
      end

      context "when admin changes another account" do
        let(:affected_admin) { other_admin }

        it "requires the password to be changed" do
          call
          expect(affected_admin.reload.password_changed_at).to be_nil
        end
      end
    end

    context "access flags" do
      let(:admin_params) do
        {access_flags: ["create_plans_with_plan_state"]}
      end

      it "adds flag to access_flags attribute" do
        call

        patch(
          :update,
          params: {
            locale: I18n.locale,
            id: other_admin.id,
            admin: {access_flags: ["create_plans_with_plan_state"]}
          }
        )
        other_admin.reload
        expect(other_admin.access_flags).to include("create_plans_with_plan_state")
      end
    end

    context "when role change validation passes" do
      let(:admin_params) do
        {role_id: other_role.id}
      end

      let(:validation_passed) { true }

      before { mock_role_change_validator }

      it "updates other admin" do
        call
        expect(response.status).to eq(302)
        expect(other_admin.reload.role).to eq(other_role)
      end
    end

    context "when role change validation fails" do
      let(:admin_params) do
        {role_id: other_role.id}
      end

      let(:validation_passed) { false }

      before { mock_role_change_validator }

      it "doesn't update other admin" do
        call
        expect(response.status).to eq(200)
        expect(response).to render_template(:edit)
        expect(other_admin.reload.role).not_to eq(other_role)
      end
    end

    context "cleanup password and password_confirmation fields" do
      render_views

      it "does't return password and password_confirmation fields when update is fails" do
        patch(
          :update,
          params: {
            locale: I18n.locale,
            id: other_admin.id,
            admin: {
              access_flags: ["create_plans_with_plan_state"],
              password: "PasswordBlaBlaBlaBla123",
              password_confirmation: "PasswordConfirmationBlaBlaBla"
            }
          }
        )
        expect(response.status).to eq 200
        expect(response.body =~ /PasswordBlaBlaBlaBla123/).to be_nil
        expect(response.body =~ /PasswordConfirmationBlaBlaBla/).to be_nil
      end
    end
  end

  describe "GET /:id/performance_classification", :integration do
    let!(:categories) do
      [
        create(:category, :high_margin, :regular),
        create(:category, :high_margin, :combo),
        create(:category, :high_margin, :umbrella),
        create(:category, :medium_margin, :regular),
        create(:category, :low_margin, :regular),
      ]
    end
    let!(:performance_classification) do
      create(:admin_performance_classification, admin: admin, level: :a, category: categories[0])
    end

    before { get :performance_classification, params: { id: admin.id, locale: I18n.locale } }

    it do
      expect(
        assigns[:performance_classifications].map do |classification|
          { category_name: classification.category_name, level: classification.level }
        end
      ).to match_array(
        [
          { category_name: performance_classification.category.name, level: "a" },
          { category_name: categories[2].name, level: "not_set" },
          { category_name: categories[3].name, level: "not_set" }
        ]
      )
    end
  end

  describe "POST /:id/update_performance_classification" do
    let(:category) { create(:category) }
    let(:level) { AdminPerformanceClassification.levels[:b] }
    let(:scope) { AdminPerformanceClassification.where(category_id: category.id, admin_id: admin.id) }

    def call
      payload = { locale: :de, format: :js, admin: { level: level, category_id: category.id } }
      post :update_performance_classification, params: { id: admin.id }.merge(payload)
    end

    context "creates a performance classification if it does not exist" do
      it do
        expect(scope).to be_blank
        call
        expect(scope.where(level: level)).to be_present
      end
    end

    context "updates a performance classification if it exists" do
      let(:init_level) { AdminPerformanceClassification.levels[:a] }
      let!(:performance_classification) do
        create(:admin_performance_classification, admin: admin, category: category, level: init_level)
      end

      it do
        expect {
          call
          performance_classification.reload
        }.to change(performance_classification, :level).from(init_level).to(level)
      end
    end
  end
end
