require 'rails_helper'

RSpec.describe Platform::RuleEngineV3::Flows::MessageToFeed do
  SomeRuleForFeed = Struct.new(:name, :content_key)

  let(:mandate) { create(:mandate) }
  let(:admin) { create(:admin) }
  let(:mailer) { double(MessageToQuestionnaireMailer) }
  let(:device) { double(Device, human_name: "some iPhone") }
  let(:subject) do
    described_class.new(mandate, admin, questionnaire, mailer, rule)
  end

  let(:rule) { SomeRuleForFeed.new('Rule', 'demand_old_rule') }

  let(:category) { create(:category, ident: '377e1f7c') }
  let(:questionnaire) do
    create(:questionnaire, category: category, identifier: 'blX9Q0')
  end

  context '#push_message' do
    it 'has metadata with identifier' do
      expect(subject.push_attributes[:identifier]).to eq('Rule')
      expect(subject.push_attributes[:title]).to eq('Clark')
    end

    it 'sends a push with identifier' do
      allow(mandate).to receive_message_chain("user_or_lead.devices.with_push_enabled").and_return([device])
      allow(PushService).to receive(:send_push_notification)
        .with(mandate, any_args)
        .and_return([device])

      expect(subject.push_attributes[:title]).to eq('Clark')
      subject.send(:deliver_push_message)

      last_push = Interaction::PushNotification.last
      expect(last_push.identifier).to eq('Rule')
    end

    context '#call' do
      it 'sends push but not e-mail' do
        expect(subject).to receive(:send_push)
        expect(subject).not_to receive(:send_email)

        subject.call
      end
    end
  end
end
