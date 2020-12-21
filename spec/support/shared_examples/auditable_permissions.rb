# frozen_string_literal: true

RSpec.shared_examples "a model with auditable permissions" do
  let(:model) do
    try(:shared_example_model) || create(ActiveModel::Naming.singular(described_class))
  end

  let(:permission) do
    create(
      :permission,
      controller: "admin_controller",
      action: "admin_action"
    )
  end

  let(:permission_fields) do
    %w[id controller action]
  end

  let(:expected_permission_fields) do
    {
      permission: permission.attributes.values_at(*permission_fields)
    }
  end

  it "includes the Permittable concern" do
    expect(model).to be_kind_of(Permittable)
  end

  context "when a permission is going to be added" do
    let(:call) { model.permission_ids = [permission.id] }

    it "adds the permission" do
      expect { call }.to change { model.permissions.count }.from(0).to(1)
    end

    it "creates a 'add_permission' business event" do
      expect(BusinessEvent).to receive(:audit)
        .with(model, "add_permission", expected_permission_fields)
      call
    end
  end

  context "when a permission is going to be removed" do
    let!(:add_permission) { model.permission_ids = [permission.id] }

    let(:call) { model.permission_ids = [] }

    it "removes the permission" do
      expect { call }.to change { model.permissions.count }.from(1).to(0)
    end

    it "creates a 'remove_permission' business event" do
      expect(BusinessEvent).to receive(:audit)
        .with(model, "remove_permission", expected_permission_fields)
      call
    end
  end
end
