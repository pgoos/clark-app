# == Schema Information
#
# Table name: roles
#
#  id         :integer          not null, primary key
#  identifier :string
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  weight     :integer          default(1)
#

require 'rails_helper'

RSpec.describe Role, :slow, type: :model do

  let(:role) do
    build(:role)
  end

  subject { role }

  it { is_expected.to be_valid }

  #
  # Settings
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Constants
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Attribute Settings
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  it { is_expected.to respond_to(:previous_permissions) }

  #
  # Plugins
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Concerns
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  it_behaves_like "a commentable model"
  it_behaves_like "an auditable model"
  it_behaves_like "a model with auditable permissions"

  #
  # Index
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # State Machine
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Associations
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  it { is_expected.to have_many(:admins).dependent(:nullify) }

  it { is_expected.to have_and_belong_to_many(:permissions) }

  #
  # Nested Attributes
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Validations
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  [:name].each do |attr|
    it { is_expected.to validate_presence_of(attr) }
  end

  # separate presence validation test since shoulda-matcher triggers before_validation callback, which sets identifier based on name
  it 'validates presence of identifier' do
    role = Role.new
    role.valid?

    expect(role.errors.messages[:identifier]).to be_present
  end

  #
  # Callbacks
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  describe "#skip_set_dentifier" do
    context "when it is true" do
      let(:role) { create(:role, name: "Role1") }

      it "keeps existing identifier" do
        role.update(
          skip_set_identifier: true,
          name: "Role2"
        )
        expect(role.identifier).to eq("role1")
      end
    end

    context "when it is false" do
      it "overrides existing identifier" do
        role.update(name: "Role2")
        expect(role.identifier).to eq("role2")
      end
    end
  end

  it_behaves_like 'a model with callbacks', :before, :validation, :set_identifier

  it_behaves_like 'a model with callbacks', :after, :save, :set_admin_permissions!

  #
  # Delegates
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Instance Methods
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Class Methods
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  describe '.exists?' do
    context 'when identifier is nil' do
      subject { Role.exists?(nil) }
      it { is_expected.to be false }
    end

    context 'when identifier exists in DB' do
      subject { Role.exists?('super_admin') }
      it { is_expected.to be true }
    end

    context 'when identifier does not exist in DB' do
      subject { Role.exists?('this_role_does_not_exist') }
      it { is_expected.to be false }
    end
  end

  #
  # Protected
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Private
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #


  describe "#set_identifier" do
    subject { role.send(:set_identifier) }

    it { expect{ subject }.not_to change(role, :identifier) }

    context "if name changed" do
      let(:new_role_name) { "new role name" }

      it "changes the identifier" do
        role.save
        role.name = new_role_name
        expect { subject }.to change(role, :identifier).to(new_role_name.parameterize(separator: "_"))
      end
    end
  end

  describe "#set_admin_permissions!" do
    subject { role.send(:set_admin_permissions!) }

    let!(:role) { create(:role, permissions: role_permissions) }
    let(:role_permissions) { create_list(:permission, 1) }
    let(:admin_permissions) { create_list(:permission, 1) }
    let(:admin) { create(:admin) }

    before { role.admins = [admin] }

    context "when previous_permissions is nil" do
      before do
        admin.update!(permissions: admin_permissions)
      end

      it do
        expect(admin.permissions).to eq(admin_permissions)
        subject
        expect(admin.reload.permissions.to_a).to match_array(admin_permissions + role_permissions)
      end
    end

    context "when previous_permissions are given" do
      let(:old_permissions) { create_list(:permission, 1) }

      before do
        role.previous_permissions = old_permissions
        admin.update!(permissions: old_permissions)
      end

      it do
        subject
        expect(admin.reload.permissions.to_a).to match_array(role_permissions)
      end
    end

    context "when admin has additional_permission" do
      let(:old_permissions) { create_list(:permission, 1) }

      before do
        role.previous_permissions = old_permissions
        admin.update!(permissions: old_permissions + admin_permissions)
      end

      it do
        subject
        expect(admin.reload.permissions.to_a).to match_array(role_permissions + admin_permissions)
      end
    end
  end
end
