RSpec.shared_examples 'an identifiable model' do
  it 'generates an ident if one isn\'t given' do
    subject.ident = nil

    expect(subject).to be_valid
    expect(subject.ident).to be_present
  end

  it 'does not change a given ident' do
    subject.save!
    subject.reload
    ident = subject.ident

    subject.save!
    subject.reload
    expect(subject.ident).to eq(ident)
  end

  it { expect(subject).to validate_uniqueness_of(:ident).case_insensitive }
end
