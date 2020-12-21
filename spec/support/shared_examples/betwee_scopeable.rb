RSpec.shared_examples 'between_scopeable' do |time_field, mandate_builder|

  describe '.between scope' do
    subject { described_class.between(start_date, end_date) }

    let(:start_date) { Time.zone.now - 3.days }
    let(:end_date) { Time.zone.now - 1.days }

    factory_name = described_class.name.underscore.gsub("/", "_").to_sym
    params = {}

    let!(:mandate) { mandate_builder.call if mandate_builder }
    let!(:event_before) do
      params.merge!(mandate: mandate) if mandate
      FactoryBot.create factory_name, params.merge!(time_field => Time.zone.now - 4.days)
    end
    let!(:event_within) do
      params.merge!(mandate: mandate) if mandate
      FactoryBot.create factory_name, params.merge!(time_field => Time.zone.now - 2.days)
    end
    let!(:event_after) do
      params.merge!(mandate: mandate) if mandate
      FactoryBot.create factory_name, params.merge!(time_field => Time.zone.now)
    end

    it 'includes only events within between start and end date'  do
      expect(subject).to match_array([event_within])
    end
  end
end
