# frozen_string_literal: true

RSpec.shared_examples "accessible" do
  let(:instance_name) { ActiveModel::Naming.singular(described_class) }
  let(:instance)      { create(instance_name) }

  context "callbacks" do
    it { expect(instance).to callback(:set_default_access_to_clark).before(:create) }
  end

  describe "public instance methods" do
    context "responds to its methods" do
      it { expect(instance).to respond_to(:acquired_by_clark?) }
      it { expect(instance).to respond_to(:acquired_by_partner?) }
      it { expect(instance).to respond_to(:accessible_only_by_clark?) }
      it { expect(instance).to respond_to(:accessible_by?) }
      it { expect(instance).to respond_to(:grant_access_for!) }
      it { expect(instance).to respond_to(:revoke_access_for!) }
    end

    context "executes methods correctly" do
      context "#acquired_by_clark?" do
        it "returns true if Clark is an owner" do
          expect(instance.acquired_by_clark?).to be_truthy
        end

        it "returns false if Clark isn't an owner" do
          instance.owner_ident = "test"
          expect(instance.acquired_by_clark?).to be_falsy
        end
      end

      context "#acquired_by_partner?" do
        it "returns true if Clark isn't an owner" do
          instance.owner_ident = "test"
          expect(instance.acquired_by_partner?).to be_truthy
        end

        it "returns false if Clark isn't an owner" do
          expect(instance.acquired_by_partner?).to be_falsy
        end
      end

      context "#accessible_only_by_clark?" do
        it "returns true if Clark is an owner and accessible_by includes only Clark ident" do
          expect(instance.accessible_only_by_clark?).to be_truthy
        end

        it "returns false if Clark isn't an owner" do
          instance.owner_ident = "test"
          expect(instance.accessible_only_by_clark?).to be_falsy
        end

        it "returns false if accessible_by includes not only Clark ident" do
          instance.accessible_by = %w[more test idents]
          expect(instance.accessible_only_by_clark?).to be_falsy
        end

        it "returns false if Clark isn't an owner and accessible_by includes multiple idents" do
          instance.accessible_by = %w[more test idents]
          expect(instance.accessible_only_by_clark?).to be_falsy
        end
      end

      context "#accessible_by?" do
        it "returns true if accessible_by includes Clark or partnership ident" do
          expect(instance.accessible_by?("clark")).to be_truthy
        end

        it "returns false if accessible_by doesn't include Clark or partnership ident" do
          expect(instance.accessible_by?("test")).to be_falsy
        end
      end

      context "#grant_access_for" do
        it "updates accessible_by set" do
          instance.grant_access_for!("test")
          expect(instance.accessible_by).to eq(%w[clark test])
        end

        it "doesn't update accessible_by set if access already was granted" do
          access = instance.accessible_by
          instance.grant_access_for!("test")
          instance.grant_access_for!("test")
          expect(instance.accessible_by).to eq(access)
        end
      end

      context "#revoke_access_for" do
        before do
          instance.grant_access_for!("test")
        end

        it "updates accessible_by set" do
          instance.revoke_access_for!("test")
          expect(instance.accessible_by).to eq(%w[clark])
        end
      end
    end
  end
end
