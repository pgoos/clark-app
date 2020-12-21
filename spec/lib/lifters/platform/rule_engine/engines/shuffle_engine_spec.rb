require 'rails_helper'

RSpec.describe Platform::RuleEngineV3::Engines::ShuffleEngine do
  let(:rule1_class) { n_double("rule1_class") }
  let(:rule1) { n_double("rule1") }
  let(:rule2_class) { n_double("rule2_class") }
  let(:rule2) { n_double("rule2") }
  let(:candidate1) { n_double("candidate1") }
  let(:candidate2) { n_double("candidate2") }
  let(:intent) { n_double("intent") }
  let!(:admin) { create(:admin) }

  let(:subject) do
    class EngineClass
      include Platform::RuleEngineV3::Engines::ShuffleEngine
      def candidates
        []
      end

      def name
        'A rule'
      end

      def feature
        'RULE_TEST_FEATURE'
      end
    end
    EngineClass.new
  end

  # TODO: The design of those tests are not the best that could be
  # TODO: Pascal - I think, this is quite a lot of mocking setup.
  # Either that subject does a lot of integration, so that an integration test would be a
  # better choice, or you could do something about the OO
  # design and strive for different abstractions.
  context '#apply_rules' do
    before(:each) do
      allow(subject).to receive(:rules).and_return([rule1_class, rule2_class])

      expect(rule2_class).to receive(:new)
                               .with(mandate: candidate1,
                                      candidate: candidate1,
                                      admin: admin).and_return(rule2)

      expect(rule2_class).to receive(:new)
                               .with({ mandate: candidate2,
                                       candidate: candidate2,
                                       admin: admin}).and_return(rule2)

      expect(rule2).to receive(:applicable?).and_return(true, false)
      expect(rule2).to receive(:intent).and_return(intent)
      allow(rule2).to receive(:name)

      expect(rule1_class).to receive(:new)
                               .with(mandate: candidate1,
                                     candidate: candidate1,
                                     admin: admin).and_return(rule1)

      expect(rule1_class).to receive(:new)
                               .with(mandate: candidate2,
                                     candidate: candidate2,
                                     admin: admin).and_return(rule1)

      expect(rule1).to receive(:applicable?).and_return(false, false)
      expect(rule1).not_to receive(:intent)
      allow(rule1).to receive(:name)

      expect(intent).to receive(:call)

      allow(subject).to receive(:trace_run)
      allow(subject).to receive(:trace_result)

      create(:feature_switch, key: subject.feature, active: true)
    end

    it 'apply every rule possible' do
      subject.apply_rules([candidate1, candidate2], admin)
    end
  end

  context 'limiting' do
    let(:mandate) { create(:mandate) }
    let(:other_mandate) { create(:mandate) }
    let(:opportunity) { create(:opportunity, mandate: mandate) }
    let(:valid_metadata) { { status: 'OK', ident: subject.name } }

    it 'is not processed' do
      expect(subject.mandates_already_processed).not_to include(mandate)
    end

    it 'is not resulted' do
      expect(subject.mandates_already_resulted).not_to include(mandate)
    end

    it 'is not tracked on entity' do
      subject.trace_run(mandate, valid_metadata, other_mandate)
      expect(subject.mandates_already_processed).not_to include(mandate)

      subject.trace_result(mandate, valid_metadata, other_mandate)
      expect(subject.mandates_already_resulted).not_to include(mandate)
    end

    it 'is tracked as a mandate from model on result' do
      subject.trace_run(opportunity, valid_metadata)
      expect(subject.mandates_already_processed).to include(mandate)
    end

    it 'is tracked as a mandate from model on run' do
      subject.trace_result(opportunity, valid_metadata)
      expect(subject.mandates_already_resulted).to include(mandate)
    end

    it 'is tracked as an alternate mandate from model on result' do
      subject.trace_run(mandate, valid_metadata, mandate)
      expect(subject.mandates_already_processed).to include(mandate)
    end

    it 'is tracked as an alternate from model on run' do
      subject.trace_result(mandate, valid_metadata, mandate)
      expect(subject.mandates_already_resulted).to include(mandate)
    end
  end
end
