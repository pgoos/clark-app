RSpec.shared_examples 'an advice for private_liability_insurance_with_animal_ownership' do |message, expected_identifier, args = {}|
  it 'sends email and push interactions' do
    expect do
      subject.private_liability_insurance_with_animal_ownership
    end.to change(product_advisable.interactions, :count).by(2)
  end

  it 'sends interpolated message content' do
    subject.private_liability_insurance_with_animal_ownership

    expect(product_advisable.advices.first).not_to be_nil

    expected_content = subject.advice_template_replacements(I18n.t(message), product_advisable)
    expect(product_advisable.advices.first.content).to eq(expected_content)
  end

  it 'interpolates the premium' do
    subject.private_liability_insurance_with_animal_ownership

    expect(product_advisable.advices.first).not_to be_nil

    pattern = Regexp.new(product_advisable.company.name.to_s)
    expect(pattern).to match(product_advisable.advices.first.content)
  end

  it 'sends an advice of the correct type' do
    subject.private_liability_insurance_with_animal_ownership

    expect(product_advisable.advices.first).not_to be_nil
    expect(product_advisable.advices.first.identifier).to eq(expected_identifier)
  end
end

