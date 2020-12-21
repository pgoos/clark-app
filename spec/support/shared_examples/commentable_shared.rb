RSpec.shared_examples 'a commentable model' do
  let(:model) { build ActiveModel::Naming.singular(described_class) }
  it { expect(model).to have_many(:comments) }
end