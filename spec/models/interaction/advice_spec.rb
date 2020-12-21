# frozen_string_literal: true
# == Schema Information
#
# Table name: interactions
#
#  id           :integer          not null, primary key
#  type         :string
#  mandate_id   :integer
#  admin_id     :integer
#  topic_id     :integer
#  topic_type   :string
#  direction    :string
#  content      :text
#  metadata     :jsonb
#  acknowledged :boolean
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#


require "rails_helper"

RSpec.describe Interaction::Advice, type: :model do
  before do
    allow(Features).to receive(:active?).and_return(false)
    allow(Features).to receive(:active?).with(Features::MESSENGER).and_return(true)
  end

  it_behaves_like "event_publishable"

  subject { build(:advice) }

  it_behaves_like "robo classifiable"

  it { is_expected.to delegate_method(:owner_ident).to(:mandate) }
  it { is_expected.to delegate_method(:accessible_by).to(:mandate) }
  it { is_expected.to delegate_method(:accessible_by?).to(:mandate) }
  it { is_expected.to delegate_method(:gkv?).to(:topic) }
  it { is_expected.to delegate_method(:name).to(:category).with_prefix }
  it { is_expected.to delegate_method(:name).to(:company).with_prefix }
  it { is_expected.to delegate_method(:name).to(:admin).with_prefix }
  it { is_expected.to delegate_method(:id).to(:product).with_prefix }

  describe "#notify_customer" do
    let(:product) { create(:product, category: category) }

    context "with regular advice" do
      let(:category) { create(:category_phv) }
      let(:advice) { create(:advice, :created_by_robo_advisor) }

      before do
        allow(MandateMailer).to receive(:notification_available).with(advice)
        advice.notify_customer
      end

      it do
        expect(MandateMailer).to have_received(:notification_available)
      end
    end

    context "with GKV" do
      let(:category) { create(:category_gkv) }
      let(:advice) { create(:advice, :created_by_robo_advisor, product: product) }

      before do
        allow(MandateMailer).to receive(:notification_available_gkv).with(advice)
        advice.notify_customer
      end

      it do
        expect(MandateMailer).to have_received(:notification_available_gkv)
      end
    end

    context "with reoccurring_advice" do
      let(:category) { create(:category_phv) }
      let(:advice) { create(:advice, :reoccurring_advice) }

      before do
        allow(MandateMailer).to receive(:reoccurring_advice_notification_available).with(advice)
        advice.notify_customer
      end

      it do
        expect(MandateMailer).to have_received(:reoccurring_advice_notification_available)
      end
    end
  end

  context "helpful method" do
    let(:advice) { subject }

    it 'returns true when helpful is set to the boolean "true"' do
      advice.helpful = true
      expect(advice.helpful).to be_truthy
    end

    it 'returns true when helpful is set to the string "true"' do
      advice.helpful = "true"
      expect(advice.helpful).to be_truthy
    end

    it 'returns false when helpful is set to the boolean "false"' do
      advice.helpful = false
      expect(advice.helpful).to be_falsey
    end

    it 'returns false when helpful is set to the string "false"' do
      advice.helpful = "false"
      expect(advice.helpful).to be_falsey
    end
  end

  context "notifying the customer for non GKV" do
    let!(:advice) { build(:advice, cta_link: "product/link") }

    it "notify_customer tries to send push, email and messenger" do
      expect(advice).to receive(:notify_by_mail)
      expect(advice).to receive(:send_push_with_sms_fallback)
      expect(advice).to receive(:send_messenger_message)

      advice.notify_customer
    end

    it "creates a push interaction when user has devices" do
      advice.mandate.user = create(:user, devices: [create(:device)])

      expect { advice.send(:send_push_with_sms_fallback) }
        .to change { Interaction::PushNotification.count }.by(1)

      push_notification = Interaction::PushNotification.last
      locale_scope      = "transactional_push.notification_available"

      expect(push_notification.title).to     eq(I18n.t("#{locale_scope}.title"))
      expect(push_notification.content).to   eq(I18n.t("#{locale_scope}.content"))
      expect(push_notification.clark_url).to eq(I18n.t("#{locale_scope}.url",
                                                       product_id: advice.topic.id))
      expect(push_notification.section).to   eq(I18n.t("#{locale_scope}.section"))
      expect(push_notification.topic).to     eq(advice.topic)
      expect(push_notification.devices).to be_present
    end

    it "does not create a push interaction when the user has no devices" do
      advice.mandate.user = create(:user, devices: [])

      expect { advice.send(:send_push_with_sms_fallback) }.not_to(change { Interaction::PushNotification.count })
    end

    it "sends out the notification_available e-mail" do
      advice.mandate.user = create(:user)

      expect(MandateMailer).to receive(:notification_available).with(advice).and_call_original
      expect { advice.send(:notify_by_mail) }.to(change { MandateMailer.deliveries.count }.by(1))
    end

    it "tags the advice upon sending it" do
      expect(advice).to receive(:notify_by_mail)
      expect(advice).to receive(:send_push_with_sms_fallback)

      time = Time.zone.now
      Timecop.freeze Time.zone.now

      advice.notify_customer
      advice.reload

      expect(advice.metadata["sent"]).to eq(time.to_i)
    end

    it "should know, if it was sent" do
      advice.notify_customer
      advice.reload

      expect(advice.sent?).to be_truthy
    end

    it "should know, if it was not sent yet" do
      expect(advice.sent?).to be_falsey
    end

    context "messenger" do
      let(:message_provider) { OutboundChannels::Messenger::MessageDelivery }
      let(:provider_double) { n_double("provider_double") }
      let(:content) do
        "Hallo #{advice.mandate.first_name},\nwir haben die Details deiner " \
        "#{advice.product.category.name} (#{advice.product.company.name}) in deiner " \
        "Übersicht ergänzt.\nDer Clark-Experte #{advice.admin.name} hat deinen Vertrag geprüft" \
        " und eine Einschätzung abgegeben.\n"
      end
      let(:mandate) { advice.mandate }
      let(:admin)   { advice.admin }
      let(:metadata) do
        {
          identifier:      "messenger.advice_message",
          created_by_robo: true,
          cta_text:        "Mehr erfahren",
          cta_link:        "/app/manager/products/#{advice.topic.id}",
          cta_section:     "manager"
        }
      end

      before do
        allow(message_provider).to receive(:new).with(content, mandate, admin, metadata)
                                                .and_return(provider_double)

        allow(provider_double).to receive(:send_message).with(push: false)
      end

      it "sends a messenger message" do
        expect(message_provider).to receive(:new).with(content, mandate, admin, metadata)
                                                       .and_return(provider_double)
        advice.send(:send_messenger_message, true)
      end

      it "sends with messenger provider setting push off" do
        expect(provider_double).to receive(:send_message).with(push: false)
        advice.send(:send_messenger_message, true)
      end
    end

    context "cta" do
      it "always has a cta to product" do
        advice.send(:send_messenger_message, true)

        expect(Interaction::Message.last.cta_link).to eq("/app/manager/products/#{advice.topic.id}")
      end
    end
  end

  describe "#i18n_gkv_key_postfix" do
    context "when category is gkv" do
      let(:advice) { create(:advice, topic: product) }
      let(:product) { create(:product, category: create(:category_gkv)) }

      it do
        expect(advice.i18n_gkv_key_postfix).to eq "_gkv"
      end
    end

    context "when reoccurring advice" do
      let(:advice) { build(:advice, :reoccurring_advice) }

      it do
        expect(advice.i18n_gkv_key_postfix).to eq "_reoccurring"
      end
    end

    context "when first advice" do
      let(:advice) { build(:advice, :created_by_robo_advisor) }

      it do
        expect(advice.i18n_gkv_key_postfix).to be_empty
      end
    end
  end

  context "notifying the customer for GKV" do
    let!(:advice) { build(:advice, cta_link: "product/link", topic: product) }

    let(:product) { create(:product_gkv) }

    it "notify_customer tries to send push, email and messenger" do
      expect(advice).to receive(:notify_by_mail)
      expect(advice).to receive(:send_push_with_sms_fallback)
      expect(advice).to receive(:send_messenger_message)

      advice.notify_customer
    end

    it "creates a push interaction when user has devices" do
      advice.mandate.user = create(:user, devices: [create(:device)])

      expect { advice.send(:send_push_with_sms_fallback) }
        .to change { Interaction::PushNotification.count }.by(1)

      push_notification = Interaction::PushNotification.last
      locale_scope      = "transactional_push.notification_available_gkv"

      expect(push_notification.title).to     eq(I18n.t("#{locale_scope}.title"))
      expect(push_notification.content).to   eq(I18n.t("#{locale_scope}.content"))
      expect(push_notification.clark_url).to eq(I18n.t("#{locale_scope}.url", product_id: advice.topic.id))
      expect(push_notification.section).to   eq(I18n.t("#{locale_scope}.section"))
      expect(push_notification.topic).to     eq(advice.topic)
      expect(push_notification.devices).to be_present
    end

    it "does not create a push interaction when the user has no devices" do
      advice.mandate.user = create(:user, devices: [])

      expect { advice.send(:send_push_with_sms_fallback) }.not_to(change { Interaction::PushNotification.count })
    end

    it "sends out the notification_available e-mail" do
      advice.mandate.user = create(:user)

      expect(MandateMailer).to receive(:notification_available_gkv).with(advice).and_call_original
      expect { advice.send(:notify_by_mail) }.to(change { MandateMailer.deliveries.count }.by(1))
    end

    it "tags the advice upon sending it" do
      expect(advice).to receive(:notify_by_mail)
      expect(advice).to receive(:send_push_with_sms_fallback)

      time = Time.zone.now
      Timecop.freeze Time.zone.now

      advice.notify_customer
      advice.reload

      expect(advice.metadata["sent"]).to eq(time.to_i)
    end

    it "should know, if it was sent" do
      advice.notify_customer
      advice.reload

      expect(advice).to be_sent
    end

    it "should know, if it was not sent yet" do
      expect(advice).not_to be_sent
    end

    context "messenger" do
      let(:message_provider) { OutboundChannels::Messenger::MessageDelivery }
      let(:provider_double) { n_double("provider_double") }
      let(:content) do
        "Hallo #{advice.mandate.first_name},\nwir haben die Details deiner " \
        "gesetzlichen Krankenversicherung (#{advice.product.company.name}) in deiner " \
        "Übersicht ergänzt.\nDer Clark-Experte #{advice.admin.name} hat die Tarifmerkmale " \
        "angesehen und eine Bewertung abgegeben.\n"
      end
      let(:mandate) { advice.mandate }
      let(:admin)   { advice.admin }
      let(:metadata) do
        {
          identifier:      "messenger.advice_message_gkv",
          created_by_robo: true,
          cta_text:        "Mehr erfahren",
          cta_link:        "/app/manager/products/#{advice.topic.id}",
          cta_section:     "manager"
        }
      end

      before do
        allow(message_provider)
          .to receive(:new)
          .with(content, mandate, admin, metadata)
          .and_return(provider_double)

        allow(provider_double).to receive(:send_message).with(push: false)
      end

      it "sends a messenger message" do
        expect(message_provider)
          .to receive(:new)
          .with(content, mandate, admin, metadata)
          .and_return(provider_double)
        advice.send(:send_messenger_message, true)
      end

      it "sends with messenger provider setting push off" do
        expect(provider_double).to receive(:send_message).with(push: false)
        advice.send(:send_messenger_message, true)
      end
    end

    context "cta" do
      it "always has a cta to product" do
        advice.send(:send_messenger_message, true)

        expect(Interaction::Message.last.cta_link).to eq("/app/manager/products/#{advice.topic.id}")
      end
    end
  end

  context "do not send e-mails when disable_email is set" do
    let(:attributes) { FactoryBot.attributes_for(:advice) }

    it "does not send e-mail when disable_email = true" do
      advice = described_class.create(attributes.merge(disable_email: true))
      allow(advice).to receive(:send_messenger_message)
      allow(advice).to receive(:send_push_with_sms_fallback)

      expect(advice).not_to receive(:notify_by_mail)

      advice.notify_customer
    end

    it "sends email when disable_email = false" do
      advice = described_class.create(attributes)
      allow(advice).to receive(:send_messenger_message)
      allow(advice).to receive(:send_push_with_sms_fallback)

      expect(advice).to receive(:notify_by_mail)

      advice.notify_customer
    end
  end

  context "notifying customers when we have errors" do
    let!(:advice) { create(:advice) }

    it "notify_customer calls e-mail even when push fails" do
      expect(advice).to receive(:notify_by_mail)

      allow(advice).to receive(:send_push_with_sms_fallback)
        .and_raise("any error happening while sending push")

      advice.notify_customer
      advice.reload

      expect(advice.metadata["errors"]["push"]).to eq("any error happening while sending push")
    end

    it "calls push even when e-mail fails" do
      allow(advice).to receive(:notify_by_mail).and_raise("any error happening while sending push")
      expect(advice).to receive(:send_push_with_sms_fallback)

      advice.notify_customer
      advice.reload

      expect(advice.metadata["errors"]["email"]).to eq("any error happening while sending push")
    end
  end
end
