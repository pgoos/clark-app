# frozen_string_literal: true

RSpec.shared_examples "an auditable model" do
  let(:model) do
    try(:shared_example_model) || create(ActiveModel::Naming.singular(described_class))
  end

  it "includes the Auditable concern" do
    expect(model).to be_kind_of(Auditable)
  end

  it "has_many BusinessEvents" do
    expect(model).to have_many(:business_events)
  end

  context "auditing C(R)UD actions" do
    it "creates a business event from the audit_create method" do
      expect(BusinessEvent).to receive(:audit).with(model, "create")
      model.send(:audit_create)
    end

    it "creates a business event from the audit_update method" do
      expect(BusinessEvent).to receive(:audit).with(model, "update")
      model.send(:audit_update)
    end

    it "creates a business event from the audit_destroy method" do
      expect(BusinessEvent).to receive(:audit).with(model, "destroy")
      model.send(:audit_destroy)
    end
  end

  context "audits state machine methods (when model is a state machine)" do
    if described_class.state_machine?
      states = described_class.state_machine.states.map(&:name)

      states.each do |state|
        context "in the state #{state}" do
          before { model.state = state }

          described_class.new(state: state).state_events.each do |event|
            it "audits transition for event \"#{event}\"" do
              # Ignore all other calls (create, update, etc)
              allow(BusinessEvent).to receive(:audit)
              allow_any_instance_of(Opportunity).to receive(:track_sales_consultant_assigned)

              # This one is actually exptected to be written to the db
              expect(BusinessEvent).to receive(:audit).with(model, event)

              model.fire_state_event(event)
            end
          end
        end
      end
    end
  end

  describe "#audited_mandate" do
    let(:audited_mandate) { model.audited_mandate }

    if described_class == Mandate
      it "returns itself if auditing a mandate object" do
        expect(audited_mandate).to eq model
      end
    else
      if described_class.instance_methods.include?(:mandate)
        it "returns the mandate if auditing an object associated with a mandate" do
          allow(model).to receive(:mandate).and_return(FactoryBot.build(:mandate))
          expect(audited_mandate).to eq(model.mandate)
        end
      end
    end
  end

  context "auditing callbacks" do
    it "executes the #audit_create_method after creation" do
      expect(model).to receive(:audit_create)
      model.run_callbacks(:create)
    end

    it "executes the #audit_update_method after updating" do
      expect(model).to receive(:audit_update)
      model.run_callbacks(:update)
    end

    it "executes the #audit_destroy_method after destroying" do
      expect(model).to receive(:audit_destroy)
      model.destroy!
    end
  end

  context "skip auditing callbacks when attr_accessor is set to true" do
    before { allow(model).to receive(:skip_audit_events).and_return(true) }

    it "skips the #audit_create_method after creation" do
      expect(BusinessEvent).not_to receive(:audit).with(model, "create")
      model.run_callbacks(:create)
    end

    it "skips the #audit_update_method after updating" do
      expect(BusinessEvent).not_to receive(:audit).with(model, "update")
      model.run_callbacks(:update)
    end
  end
end
