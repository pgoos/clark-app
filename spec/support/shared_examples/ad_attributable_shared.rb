RSpec.shared_examples 'an ad attributable model' do
  let(:model) { build ActiveModel::Naming.singular(described_class) }
  let(:sample_model) { create(:user, mandate: create(:mandate)) }

  it 'includes the AdAttributable concern' do
    expect(model).to be_a_kind_of(AdAttributable)
  end

  it 'should provide empty advertiser ids initially' do
    expect(model.advertiser_ids).to be_empty
  end

  it 'should add gps_adid values' do
    expected_type = 'type'
    expected_id = 'ABC'
    model.add_advertiser_id 'id' => expected_id, 'type' => expected_type
    expect(model.advertiser_ids[expected_id]).to eq(expected_type)
    expect(model.has_advertiser_id?('id' => expected_id, 'type' => expected_type)).to be_truthy
  end

  it 'should ignore values without id' do
    model.add_advertiser_id 'id' => nil, 'type' => 'type'
    expect(model.advertiser_ids).to be_empty
  end

  it 'should ignore values with empty id' do
    model.add_advertiser_id 'id' => '', 'type' => 'type'
    expect(model.advertiser_ids).to be_empty
  end

  it 'may not fail, if the param is nil' do
    expect {
      model.add_advertiser_id nil
    }.to_not raise_exception
    expect(model.advertiser_ids).to be_empty
  end

  it 'should save if added an advertiser id' do
    expected_type = 'type'
    expected_id = 'ABC'
    expect(model).to receive(:save!)
    model.update_advertiser_ids 'id' => expected_id, 'type' => expected_type
    expect(model.has_advertiser_id?('id' => expected_id, 'type' => expected_type)).to be_truthy
  end

end