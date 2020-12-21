RSpec.shared_examples 'a robo advice' do
  it 'should create an advice' do
    expect(advice).to be_an(Interaction::Advice)
  end

  it 'should be connected to the old product' do
    expect(advice.product).to eq(product)
  end

  it 'should know the mandate' do
    expect(advice.mandate).to eq(mandate)
  end

  it 'should have an arbitrary advice admin' do
    create(:admin)
    expect(advice.admin).to eq(advice_admin)
  end

  it 'is created by the robo advisor' do
    expect(advice.created_by_robo_advisor).to be_truthy
  end

  it 'should not contain a cta link' do
    expect(advice.cta_link).to be_nil
  end

  it 'should be persisted' do
    expect(advice).to be_persisted
  end
end
