# == Schema Information
#
# Table name: permissions
#
#  id         :integer          not null, primary key
#  controller :string
#  action     :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require "rails_helper"

RSpec.describe Permission, :slow, type: :model do
  subject { permission }

  let(:permission) do
    build(:permission)
  end

  it { is_expected.to be_valid }

  it_behaves_like "an auditable model"

  it { is_expected.to have_and_belong_to_many(:admins) }
  it { is_expected.to have_and_belong_to_many(:roles) }

  %i[controller action].each do |attr|
    it { is_expected.to validate_presence_of(attr) }
  end

  it { is_expected.to validate_uniqueness_of(:action).scoped_to(:controller) }

  describe "#name" do
    subject { permission.name }

    before do
      permission.controller = "my controller"
      permission.action = "my action"
    end

    it { is_expected.to eq "my controller/my action" }
  end

  describe ".sync_and_permit_admins!" do
    subject { Permission.sync_and_permit_admins! }

    before do
      allow(Permission).to receive(:synchronize_routes).and_return(true)
      allow(Permission).to receive(:permit_super_admin!).and_return(true)
    end

    it do
      is_expected.to be true
      expect(Permission).to have_received(:synchronize_routes).once
      expect(Permission).to have_received(:permit_super_admin!).once
    end
  end

  describe ".synchronize_routes" do
    subject { Permission.synchronize_routes }

    let(:sample_route) { Rails.application.routes.routes.last }

    before do
      allow(sample_route).to receive(:requirements).and_return(controller: "thisisatest", action: "index") # avoid fixtures
      allow(Permission).to receive(:wanted_routes).and_return([sample_route]) # use only one sample route for performance reasons
    end

    it { expect { subject }.to change{ Permission.where(controller: sample_route.requirements[:controller], action: sample_route.requirements[:action]).all.count }.from(0).to(1) }

    context "route already exist" do
      let(:existing_permission) { Permission.create!(controller: "thisisatest", action: "testaction") }

      it "does not remove existing permissions" do
        subject
        expect(existing_permission.reload).not_to be_nil
      end
    end
  end

  describe ".permit_super_admin!" do
    subject { Permission.permit_super_admin! }

    let(:super_admin) { double('Role') }
    let(:permission_ids) { [1, 2, 3] }

    before do
      allow(Permission).to receive(:pluck).and_return(permission_ids)
      allow(super_admin).to receive(:update_attributes).and_return(true)
    end

    context "when role super_admin exists" do
      before { allow(Role).to receive(:find_by).with(identifier: :super_admin).and_return(super_admin) }

      it do
        is_expected.to be true
        expect(super_admin).to have_received(:update_attributes).with(permission_ids: permission_ids)
      end
    end

    context "when role super_admin does not exist" do
      before { allow(Role).to receive(:find_by).with(identifier: :super_admin).and_return(nil) }

      it do
        is_expected.to be_falsey
        expect(super_admin).not_to have_received(:update_attributes)
      end
    end
  end

  describe ".route_wanted?" do
    let(:wanted_route) { double("Route", requirements: { controller: (([Settings.permissions.namespaces.first] + ["controller_name"]).join("/")) }) }
    let(:unwanted_route) { double("Route", requirements: { controller: "some_strange_namespace/controller_name" }) }

    context "when no options are given" do
      it { expect(Permission.route_wanted?(wanted_route)).to be true }
      it { expect(Permission.route_wanted?(unwanted_route)).to be false }
    end

    context "when namespaces are changed in options" do
      it { expect(Permission.route_wanted?(wanted_route, namespaces: ["some_strange_namespace"])).to be false }
      it { expect(Permission.route_wanted?(unwanted_route, namespaces: ["some_strange_namespace"])).to be true }
    end
  end

  describe ".wanted_routes" do
    Permission.wanted_routes.each do |route|
      it { expect(route.requirements[:controller]).to match(/(#{Settings.permissions.namespaces.join("|")})/) }
    end
  end
end
