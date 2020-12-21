RSpec.shared_examples 'v4 automation' do |flags = []|
  let(:feature_name) { "AUTOMATED_#{expected_name.upcase}" }

  context 'name and metadata' do
    it { expect(subject.ident).to eq(expected_name) }
    it { expect(subject.content_key).not_to be_nil }
    it { expect(subject.feature).to eq(feature_name) }
  end

  context '.candidates' do
    it { expect(subject.candidates.count).not_to eq(0) }
    it { expect(subject.candidates.first).to be_a(candidate.class) }

    it "does not operate twice on candidates" do
      candidate = subject.candidates.first
      mandate = candidate.try(:mandate) || candidate

      expect(subject.candidates.count).to eq(1)
      RuleHelper.simulate_execution(subject, candidate, mandate)
      expect(subject.candidates.count).to eq(0)
    end
  end

  unless flags.include?(:skip_applicable)
    context 'applicable?' do
      it 'validates applicability on candidates' do
        candidates.each_pair do |candidate, expected|
          result = subject.applicable?(candidate)
          expect(result).to eq(expected), "#{candidate} should be #{expected}"
        end
      end
    end
  end

  unless flags.include?(:candidate_context)
    context 'situation' do
      let(:situation_sample) { situation_class.new(candidate) }
      it 'respond to interface' do
        situation_expectations.each do |expectation|
          result = situation_sample.respond_to?(expectation)
          expect(result).to eq(true), "should respond_to? #{expectation}"
        end
      end

      it { expect(subject.situation(candidate)).to be_a(situation_class) }
    end
  else
    context 'candidate context' do
      it 'creates a candidate context for the rule' do
        expect(subject).to respond_to(:create_candidate_context)
      end
    end
  end

  unless flags.include?(:not_compatible)
    context 'intent' do
      let(:result_intent) { subject.intent(intent_options) }
      it { expect(result_intent).to be_a(intent_class) }
    end
  end

  context 'rule processing' do
    let!(:feature_switch) { create(:feature_switch,
                                               key: feature_name,
                                               active: true) }

    before(:each) do
      allow(subject).to receive(:trace_run)
      allow(subject).to receive(:trace_result)
    end

    it 'run' do
      candidates.each_pair do |candidate, expectation|
        allow(subject).to receive(:situation).and_return(candidate) unless flags.include?(:candidate_context)
        result = subject.run([candidate], admin)
        if expectation
          expect(result.first).to be_a(intent_class)
        else
          expect(result).to be_empty
        end
      end
    end
  end
end
