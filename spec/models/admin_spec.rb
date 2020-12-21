# frozen_string_literal: true

# == Schema Information
#
# Table name: admins
#
#  id                     :integer          not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  created_at             :datetime
#  updated_at             :datetime
#  role_id                :integer
#  state                  :string
#  first_name             :string
#  last_name              :string
#  profile_picture        :string
#  email_footer_image     :string
#  work_items             :string           default([]), is an Array
#  access_flags           :string           default([]), is an Array
#  sip_uid                :string
#  failed_attempts        :integer          default(0), not null
#  unlock_token           :string
#  locked_at              :datetime
#  password_changed_at    :datetime
#

require "rails_helper"

RSpec.describe Admin, type: :model do
  # Setup

  subject { admin }

  let(:admin) do
    admin      = build_stubbed(:admin)
    admin.role = build_stubbed(:role)
    admin
  end

  it { is_expected.to be_valid }

  # Settings
  # Constants
  # Attribute Settings
  # Plugins

  # Concerns

  it_behaves_like "an activatable model"
  it_behaves_like "an auditable model"
  it_behaves_like "a model with auditable permissions"

  # Index
  # State Machine
  # Scopes
  describe ".with_access" do
    subject { Admin.with_access("sales_consultation") }

    let!(:admins) do
      [
        create(:admin, access_flags: ["sales_consultation"]),
        create(:admin, access_flags: [])
      ]
    end

    it "returns records with_access" do
      expect(subject).to eq [admins.first]
    end
  end

  # Associations

  it { is_expected.to belong_to(:role) }
  it { is_expected.to have_and_belong_to_many(:permissions) }

  it { is_expected.to have_many(:follow_ups) }
  it { is_expected.to have_many(:interactions) }
  it { is_expected.to have_many(:opportunities) }
  it { expect(subject).to have_many(:executed_business_events).class_name("BusinessEvent") }

  # Nested Attributes

  # Validations

  it_behaves_like "a model requiring a password only for new records"
  it { is_expected.to validate_presence_of(:role_id) }

  context "password complexity" do
    it "requires a number" do
      admin = FactoryBot.build(:admin, password: "TestTest!")

      expect(admin).not_to be_valid
      expect(admin.errors[:password])
        .to include(I18n.t("activerecord.errors.models.user.password_complexity"))
    end

    it "requires an uppercase letter" do
      admin = FactoryBot.build(:admin, password: "test1234!")

      expect(admin).not_to be_valid
      expect(admin.errors[:password])
        .to include(I18n.t("activerecord.errors.models.user.password_complexity"))
    end

    it "requires a lowercase letter" do
      admin = FactoryBot.build(:admin, password: "TEST1234!")

      expect(admin).not_to be_valid
      expect(admin.errors[:password])
        .to include(I18n.t("activerecord.errors.models.user.password_complexity"))
    end

    it "validates complex password" do
      admin = FactoryBot.build(:admin, password: "Dreefach-12")
      expect(admin).to be_valid
    end

    it "is valid with lower-, uppercase and number" do
      admin = FactoryBot.build(:admin, password: Settings.seeds.default_password)

      expect(admin).to be_valid
      expect(admin.errors[:password]).to be_empty
    end
  end

  context "password expiring" do
    it "disables settings for password expiring" do
      Devise.expire_password_after = false
      admin = FactoryBot.create(:admin, password: Settings.seeds.default_password)
      expect(Devise.expire_password_after).to eq false
      admin.update_column :password_changed_at, 91.days.ago
      expect(admin.password_expired?).to eq false
      admin.update_column :password_changed_at, 1.day.ago
      expect(admin.password_expired?).to eq false
    end
  end

  describe "#expire_password_at!" do
    let(:admin) do
      build(
        :admin,
        password_changed_at: Time.zone.now
      )
    end

    let(:password_expires_after) { 14 }

    let(:call) { admin.expire_password_at! }

    context "when initial password expiration is enabled" do
      before do
        allow(Admin).to receive("initial_password_expiration_enabled?")
          .and_return(true)

        allow(Admin).to receive("expire_password_after")
          .and_return(true)
      end

      let(:current_time) { Time.zone.parse("2019-01-01 00:00:00") }
      let(:expected_time) { current_time + password_expires_after.days }

      it "sets password_expires_at field" do
        Timecop.freeze(current_time) do
          call
          expect(admin.password_expires_at).to eq(expected_time)
        end
      end

      it "sets password_changed_at to nil" do
        call
        expect(admin.password_changed_at).to be_nil
      end

      it "saves the record" do
        call
        expect(admin).to be_persisted
      end
    end

    context "when initial password expiration is disabled" do
      before do
        allow(Admin).to receive("initial_password_expiration_enabled?")
          .and_return(false)
      end

      it "doesn't set password_expires_at field" do
        call
        expect(admin.password_expires_at).to be_nil
      end

      it "doesn't set password_changed_at to nil" do
        call
        expect(admin.password_changed_at).not_to be_nil
      end

      it "doesn't save the record" do
        call
        expect(admin).not_to be_persisted
      end
    end
  end

  describe "check previous passwords", integration: true do
    let!(:admin) do
      create(
        :admin,
        password: generate_password,
        password_confirmation: generate_password
      )
    end

    def update_password_n_times(num)
      num.times do |count|
        count += 2
        admin.update(
          password: generate_password(count),
          password_confirmation: generate_password(count)
        )
      end
    end

    def assign_password(password)
      admin.assign_attributes(
        password: password,
        password_confirmation: password
      )
    end

    before { update_password_n_times(5) }

    context "when change password to the first one" do
      before { assign_password(generate_password(1)) }

      it "is invalid" do
        expect(admin).to be_invalid
        expect(admin.errors[:password]).to(
          include(I18n.t("errors.messages.taken_in_past"))
        )
      end
    end

    context "when change password to the last one" do
      before { assign_password(generate_password(6)) }

      it "is invalid" do
        expect(admin).to be_invalid
        expect(admin.errors[:password]).to(
          include(I18n.t("errors.messages.taken_in_past"))
        )
      end
    end

    context "when change password to the correct one" do
      before { assign_password(generate_password(7)) }

      it "is valid" do
        expect(admin).to be_valid
      end
    end
  end

  describe "session expiration" do
    let(:expected_timeout_in) {
      if Settings.devise.timeout_in_mins.present?
        Settings.devise.timeout_in_mins.to_i.minutes
      else
        60.minutes
      end
    }

    it "checks if Timeoutable has been added to the Admin model" do
      expect(admin.methods.include?(:timeout_in)).to be true
    end

    it "checks if admin session expiration has been set correctly" do
      expect(admin.timeout_in).to eq expected_timeout_in
    end

    it "checks if Devise is really timing out the admin's session as expected" do
      expect(admin.timedout?(expected_timeout_in.ago)).to be true
    end
  end

  describe "#phone_number" do
    let(:admin) { build(:admin, phone_number: phone_number) }

    context "locale is AT" do
      before do
        allow(Internationalization).to receive(:locale).and_return(:at)
      end

      context "empty phone number" do
        let(:phone_number) { "" }

        it "is valid" do
          expect(admin).to be_valid
        end
      end

      context "valid phone number" do
        let(:phone_number) { "+4312345678" }

        it "is valid" do
          expect(admin).to be_valid
        end
      end

      context "invalid phone number" do
        let(:phone_number) { "+4112345678" }

        it "is invalid" do
          expect(admin).to be_invalid
        end
      end
    end

    context "locale is DE" do
      before do
        allow(Internationalization).to receive(:locale).and_return(:de)
      end

      context "empty phone number" do
        let(:phone_number) { "" }

        it "is valid" do
          expect(admin).to be_valid
        end
      end

      context "valid phone number" do
        let(:phone_number) { "+4912345678" }

        it "is valid" do
          expect(admin).to be_valid
        end
      end

      context "invalid phone number" do
        let(:phone_number) { "+4112345678" }

        it "is invalid" do
          expect(admin).to be_invalid
        end
      end
    end
  end

  # Callbacks

  it_behaves_like "a model with callbacks", :after, :save, :refresh_permissions

  context "updating admin" do
    let(:role) { create(:role, permissions: [create(:permission)]) }
    let(:new_role) { create(:role, permissions: [create(:permission)]) }
    let(:admin) { create(:admin, role: role) }

    context "updating role" do
      it "updates permissions" do
        admin.update!(role: new_role)
        expect(admin.reload.permissions).to eq new_role.permissions
      end
    end

    context "not updating role" do
      it "does not update permissions" do
        admin.update!(email: Faker::Internet.email)
        expect(admin).not_to receive(:refresh_permissions)
      end
    end
  end

  # Delegates

  # Instance Methods

  describe "#permitted_to?" do
    subject { admin.permitted_to? }

    context "when admin in status inactive" do
      before { allow(admin).to receive(:inactive?).and_return(true) }

      it { is_expected.to be false }
    end

    context "when admin not in status inactive" do
      before { allow(admin).to receive(:inactive?).and_return(false) }

      context "when args are nil" do
        it { is_expected.to be false }
      end

      context "when path is given" do
        subject do
          admin.permitted_to?(Rails.application.routes.url_helpers.admin_admins_path(locale: :en))
        end

        context "when path is permitted" do
          before do
            admin.permissions << Permission.find_by(controller: "admin/admins", action: "index")
          end

          it { is_expected.to be true }
        end

        context "when path is unpermitted" do
          it { is_expected.to be false }
        end

        context "when invalid URL is given" do
          subject { admin.permitted_to?("this/path/is/invalid/@\#$%^&*") }

          it { is_expected.to be true }
        end
      end

      context "with logout action" do
        it "returns true" do
          expect(admin.permitted_to?(controller: "admin/sessions", action: "destroy")).to be true
        end
      end

      context "with account update action" do
        it "returns true" do
          expect(admin.permitted_to?(controller: "admin/admins", action: "update", id: admin.id)).to be true
        end
      end

      context "with account edit action" do
        it "returns true" do
          expect(admin.permitted_to?(controller: "admin/accounts", action: "edit")).to be true
        end
      end

      context "when controller and action are given" do
        subject { admin.permitted_to?(controller: "admin/admins", action: "index") }

        context "when controller and action are permitted" do
          before do
            admin.permissions << Permission.find_by(controller: "admin/admins", action: "index")
          end

          it { is_expected.to be true }
        end

        context "when the association is saved on the user" do
          let(:queries) { [] }

          before do
            admin.permissions.load_target

            ActiveSupport::Notifications.subscribe("sql.active_record") do |_, sql:, **|
              queries.push(sql)
            end
          end

          it "does not hit the database to query different controllers and actions" do
            admin.permitted_to?(controller: "admin/admins", action: "index")
            admin.permitted_to?(controller: "admin/admins", action: "show")
            admin.permitted_to?(controller: "admin/admins", action: "new")
            admin.permitted_to?(controller: "admin/categories", action: "index")

            admin.permitted_to?(controller: "admin/admins", action: "index")
            expect(queries.size).to eq 0
          end
        end

        context "when controller has no namespace" do
          subject { admin.permitted_to?(controller: "some_controller", action: "index") }

          it { is_expected.to be true }
        end
      end

      context "when neither path nor controller and action are given" do
        subject { admin.permitted_to?(some_parameter: "some_parameter_value") }

        it { is_expected.to be true }
      end
    end
  end

  describe "#role? checker methods" do
    before { subject.role = Role.find_by(identifier: "super_admin") } # assign role 'super_admin'

    it { expect(subject).to respond_to(:super_admin?) }
    it { expect(subject).to respond_to(:finance_agent?) }
    it { expect(subject).not_to respond_to(:this_role_does_not_exist?) }

    it { expect(subject.super_admin?).to be true }
    it { expect(subject.finance_agent?).to be false }
    it { expect { subject.this_role_does_not_exist? }.to raise_error(NoMethodError) }
  end

  # Class Methods

  describe "#refresh_permissions" do
    let(:role) { create(:role, permissions: [create(:permission)]) }
    let(:admin) { create(:admin, role: role) }

    before do
      admin.permissions.delete_all
    end

    it "reassigns permissions to admin" do
      expect {
        admin.refresh_permissions
      }.to change { admin.permissions.count }.by(1)
    end
  end
end
