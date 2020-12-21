RSpec.shared_examples "a commissionable model" do
  let(:model) { build ActiveModel::Naming.singular(described_class) }
end
