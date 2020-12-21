require 'rails_helper'

RSpec.describe Platform::RuleEngineV3::Flows::MessageToQuestionnaire do
  SomeRuleForQuestionnaire = Struct.new(:name, :content_key)

  let(:mandate) { create(:mandate) }
  let(:admin) { create(:admin) }
  let(:mailer) { double(MessageToQuestionnaireMailer) }
  let(:subject) { described_class.new(mandate, admin, questionnaire, mailer, rule) }
  let(:rule) { SomeRuleForQuestionnaire.new('Rule', 'dental_insurance') }

  let(:category) { create(:category, ident: '377e1f7c')}
  let(:questionnaire) { create(:questionnaire, category: category, identifier: 'blX9Q0') }

  before(:each) do
    allow(mailer).to receive_message_chain('dental_insurance.deliver_now')
  end

  context '#initialize' do
    it 'is initialized with a mandate' do
      expect {
        described_class.new(mandate, admin, questionnaire, mailer, rule)
      }.not_to raise_error
    end
  end

  context '#call' do
    let(:device) { double(Device, human_name: "some iPhone") }
    before do
      allow(mandate).to receive_message_chain("user_or_lead.devices.with_push_enabled").and_return([device])
      allow(PushService).to receive(:send_push_notification)
        .with(mandate, any_args)
        .and_return([device])
    end

    context '[push notification]' do
      it 'sends when pushable devices' do
        subject.call
        mandate.reload

        expect(mandate.interactions.count).to eq(1)
      end

      it 'does not send when no pushable devices' do
        allow(mandate).to receive_message_chain("user_or_lead.devices.with_push_enabled").and_return([])

        subject.call

        mandate.reload
        expect(mandate.interactions.count).to eq(0)
      end
    end

    context 'sends email' do
      it 'alwaysMessageToQuestionnaireMailer' do
        subject.call
        mandate.reload

        expect(mandate.interactions.count).to eq(1)
      end

      it 'with the message_question template' do
        expect(mailer).to receive_message_chain('dental_insurance.deliver_now')

        subject.call
      end
    end

    it 'is wrapped on send_or_log_error' do
      expect(subject).to receive(:send_or_log_error).exactly(2)

      subject.call
    end

    it 'runs both messages without errors' do
      expect{
        subject.send(:deliver_email_message)
        subject.send(:deliver_push_message)
      }.not_to raise_error
    end

    context 'pushes sent' do
      it 'have a meaningful message' do
        subject.call
        push = mandate.interactions.last

        expect(push.content).to eq('Zahnzusatzversicherung beim Testsieger zu Top-Konditionen: Ohne Wartezeit, ohne Gesundheitsprüfung. Jetzt mehr erfahren!')
      end

      it 'have a meaningful title' do
        subject.call
        push = mandate.interactions.last

        expect(push.title).to eq('Clark')
      end

      it 'have a questionnaire url' do
        subject.call
        push = mandate.interactions.last

        expect(push.clark_url).to eq('/de/app/questionnaire/blX9Q0')
      end

      it 'have a questionnaire section' do
        subject.call
        push = mandate.interactions.last

        expect(push.section).to eq('manager')
      end

      it 'is created by admin' do
        subject.call
        push = mandate.interactions.last

        expect(push.admin).to eq(admin)
      end

      it 'have been created_by_robo_advisor' do
        subject.call
        push = mandate.interactions.last

        expect(push.created_by_robo_advisor).to eq(true)
      end
    end
  end
end
