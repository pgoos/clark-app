# frozen_string_literal: true

require "rails_helper"

describe Core::TransactionalMailer, :integration do
  let(:subject) { Core::TransactionalMailer.new(Logger.new("/dev/null")) }

  before do
    allow(Comfy::Cms::Site).to receive(:find_by) \
      .and_return Comfy::Cms::Site.new(hostname: "0.0.0.0:3000")
  end

  context "Confirmation Reminder" do
    let!(:mandate) { create(:mandate, state: "created", updated_at: 1.week.ago) }
    let!(:user) { create(:user, confirmation_sent_at: 1.week.ago, confirmed_at: nil, mandate: mandate) }

    it "sends a confirmation reminder to a user when a mandate is not in_creation" do
      expect(MandateMailer).to receive(:confirmation_reminder).and_call_original
      expect do
        subject.confirmation_reminder
      end.to change { mandate.documents.where(document_type: DocumentType.confirmation_reminder).count }.from(0).to(1)
    end

    it "updates the confirmation_sent_at timestamp when sending a new token" do
      Timecop.freeze do
        subject.confirmation_reminder

        user.reload
        expect(user.confirmation_sent_at.to_datetime).to be_within(1.second).of(DateTime.now)
      end
    end

    it "generates a new token" do
      expect do
        subject.confirmation_reminder
        user.reload
      end.to change { user.confirmation_token }
    end

    it "does not raise an exception if the e-mail is invalid" do
      # The error happens in the Mandrill Gem, so we cannot emulate this here. Instead we throw the same exception
      # through a mock and see that the mailer handles it correctly

      expect(MandateMailer).to receive(:confirmation_reminder).and_raise(NoMethodError, "undefined method `formatted' for #<Mail::UnstructuredField:0x...>")

      expect do
        subject.confirmation_reminder
      end.not_to raise_error
    end

    it "does not send the reminder if the last one was sent less than a week ago" do
      mandate.documents << create(:document, document_type: DocumentType.confirmation_reminder, created_at: 2.days.ago)

      expect(MandateMailer).not_to receive(:confirmation_reminder)
      expect do
        subject.confirmation_reminder
      end.not_to change { mandate.documents.where(document_type: DocumentType.confirmation_reminder).count }
    end

    it "sends out a second mail if the email is still not confirmed and last mail was sent out more than a week ago" do
      mandate.documents << create(:document, document_type: DocumentType.confirmation_reminder, created_at: 8.days.ago)

      expect(MandateMailer).to receive(:confirmation_reminder).and_call_original
      expect do
        subject.confirmation_reminder
      end.to change { mandate.documents.where(document_type: DocumentType.confirmation_reminder).count }.by(1)
    end

    it "sends out a third mail if the email is still not confirmed and last mail was sent out more than a week ago" do
      mandate.documents << create(:document, document_type: DocumentType.confirmation_reminder, created_at: 15.days.ago)
      mandate.documents << create(:document, document_type: DocumentType.confirmation_reminder, created_at: 8.days.ago)

      expect(MandateMailer).to receive(:confirmation_reminder).and_call_original
      expect do
        subject.confirmation_reminder
      end.to change { mandate.documents.where(document_type: DocumentType.confirmation_reminder).count }.by(1)
    end

    it "does not send a fourth reminder" do
      mandate.documents << create(:document, document_type: DocumentType.confirmation_reminder, created_at: 22.days.ago)
      mandate.documents << create(:document, document_type: DocumentType.confirmation_reminder, created_at: 15.days.ago)
      mandate.documents << create(:document, document_type: DocumentType.confirmation_reminder, created_at: 8.days.ago)

      expect(MandateMailer).not_to receive(:confirmation_reminder)
      expect do
        subject.confirmation_reminder
      end.not_to change { mandate.documents.where(document_type: DocumentType.confirmation_reminder).count }
    end
  end

  context "Mandate Mailer" do
    let(:mandate) { create(:mandate, state: "in_creation", created_at: 1.day.ago) }
    let!(:user) { create(:user, mandate: mandate) }

    before do
      allow(Features).to receive(:active?).and_return true
      allow(Features).to receive(:active?).with(Features::MESSAGE_ONLY).and_return(false)
    end

    context "Mandate Reminder #1" do
      it "sends the reminder when a mandate is in_creation for at least 1 day" do
        expect(MandateMailer).to receive(:reminder).and_call_original

        expect {
          subject.mandate_reminder1
        }.to change { mandate.documents.where(document_type: DocumentType.reminder).count }.by(1)
      end

      it "does not raise an exception if the e-mail is invalid" do
        # The error happens in the Mandrill Gem, so we cannot emulate this here. Instead we throw the same exception
        # through a mock and see that the mailer handles it correctly

        expect(MandateMailer).to receive(:reminder).and_raise(NoMethodError, "undefined method `formatted' for #<Mail::UnstructuredField:0x...>")

        expect do
          subject.mandate_reminder1
        end.not_to raise_error
      end

      it "does not send out the reminder twice" do
        mandate.documents << create(:document, document_type: DocumentType.reminder)

        expect(MandateMailer).not_to receive(:reminder)
        expect do
          subject.mandate_reminder1
        end.not_to change { mandate.documents.where(document_type: DocumentType.reminder).count }
      end

      it "sends out the reminder via push when the mandate has devices" do
        expect(MandateMailer).to receive_message_chain("reminder.deliver_now")

        mandate.user.devices << create(:device)

        expect {
          subject.mandate_reminder1
        }.to have_enqueued_job(PushNotificationJob).with(mandate.id, "reminder")
      end

      context "when mandate was created earlier than yesterday" do
        let(:mandate) { create(:mandate, state: "in_creation", created_at: 2.days.ago) }

        it "does not send an reminder" do
          expect(MandateMailer).not_to receive(:reminder)
          subject.mandate_reminder1
        end
      end

      context "when the mandate created is coming from a seo landing page" do
        let(:mandate) { create(:mandate, state: "in_creation", created_at: 1.day.ago) }
        let!(:lead) { create(:lead, source_data: {seo_lead: true}, mandate: mandate) }

        it "does not send an reminder" do
          expect(MandateMailer).not_to receive(:reminder)
          expect {
            subject.mandate_reminder1
          }.not_to change { mandate.documents.where(document_type: DocumentType.reminder).count }
        end
      end
    end

    context "Mandate Reminder #2" do
      let(:mandate) { create(:mandate, state: "in_creation", created_at: 3.days.ago) }

      before do
        mandate.documents << create(:document, document_type: DocumentType.reminder)
      end

      it "sends the reminder when a mandate is in_creation and mandates was created 3 days ago" do
        expect(MandateMailer).to receive(:reminder2).and_call_original
        expect do
          subject.mandate_reminder2
        end.to change { mandate.documents.where(document_type: DocumentType.reminder2).count }.from(0).to(1)
      end

      it "does not send out the reminder twice" do
        mandate.documents << create(:document, document_type: DocumentType.reminder2)

        expect(MandateMailer).not_to receive(:reminder2)
        expect do
          subject.mandate_reminder2
        end.not_to change { mandate.documents.where(document_type: DocumentType.reminder2).count }
      end

      it "does not raise an exception if the e-mail is invalid" do
        # The error happens in the Mandrill Gem, so we cannot emulate this here. Instead we throw the same exception
        # through a mock and see that the mailer handles it correctly

        expect(MandateMailer).to receive(:reminder2).and_raise(NoMethodError, "undefined method `formatted' for #<Mail::UnstructuredField:0x...>")

        expect do
          subject.mandate_reminder2
        end.not_to raise_error
      end

      it "sends out the reminder via push when the mandate has devices" do
        expect(MandateMailer).to receive_message_chain("reminder2.deliver_now")

        mandate.user.devices << create(:device)
        expect {
          subject.mandate_reminder2
        }.to have_enqueued_job(PushNotificationJob).with(mandate.id, "reminder2")
      end

      context "when mandate was created earlier more than 3 days ago" do
        let!(:mandate) { create(:mandate, state: "in_creation", created_at: 4.days.ago) }

        it "does not send an reminder" do
          expect(MandateMailer).not_to receive(:reminder2)
          subject.mandate_reminder2
        end
      end

      context "when the mandate created is coming from a seo landing page" do
        let(:mandate) { create(:mandate, state: "in_creation", created_at: 3.days.ago) }
        let!(:lead) { create(:lead, source_data: {seo_lead: true}, mandate: mandate) }

        it "does not send an reminder" do
          expect(MandateMailer).not_to receive(:reminder2)
          expect {
            subject.mandate_reminder2
          }.not_to change { mandate.documents.where(document_type: DocumentType.reminder2).count }
        end
      end
    end

    context "Mandate Reminder #3" do
      let(:mandate) { create(:mandate, state: "in_creation", created_at: 6.days.ago) }

      before do
        mandate.documents << create(:document, document_type: DocumentType.reminder2)
      end

      it "sends the reminder when a mandate is in_creation and mandate was created 6 days ago" do
        expect(MandateMailer).to receive(:reminder3).and_call_original
        expect do
          subject.mandate_reminder3
        end.to change { mandate.documents.where(document_type: DocumentType.reminder3).count }.from(0).to(1)
      end

      it "does not send out the reminder twice" do
        mandate.documents << create(:document, document_type: DocumentType.reminder3)

        expect(MandateMailer).not_to receive(:reminder3)
        expect do
          subject.mandate_reminder3
        end.not_to change { mandate.documents.where(document_type: DocumentType.reminder3).count }
      end

      it "does not raise an exception if the e-mail is invalid" do
        # The error happens in the Mandrill Gem, so we cannot emulate this here. Instead we throw the same exception
        # through a mock and see that the mailer handles it correctly

        expect(MandateMailer).to receive(:reminder3).and_raise(NoMethodError, "undefined method `formatted' for #<Mail::UnstructuredField:0x...>")

        expect do
          subject.mandate_reminder3
        end.not_to raise_error
      end

      it "sends out the reminder via push when the mandate has devices" do
        allow(MandateMailer).to receive_message_chain("reminder3.deliver_now")
        allow(PushService).to receive(:send_push_notification).and_return([double(Device, human_name: "some iPhone")])

        mandate.user.devices << create(:device)
        expect {
          subject.mandate_reminder3
        }.to have_enqueued_job(PushNotificationJob).with(mandate.id, "reminder3")
      end

      context "when mandate was created earlier more than 6 days ago" do
        let!(:mandate) { create(:mandate, state: "in_creation", created_at: 7.days.ago) }

        it "does not send an reminder" do
          expect(MandateMailer).not_to receive(:reminder3)
          subject.mandate_reminder3
        end
      end

      context "when the mandate created is coming from a seo landing page" do
        let(:mandate) { create(:mandate, state: "in_creation", created_at: 6.days.ago) }
        let!(:lead) { create(:lead, source_data: {seo_lead: true}, mandate: mandate) }

        it "does not send an reminder" do
          expect(MandateMailer).not_to receive(:reminder3)
          expect {
            subject.mandate_reminder3
          }.not_to change { mandate.documents.where(document_type: DocumentType.reminder3).count }
        end
      end
    end
  end

  context "Mandate ING-Diba reminder email for IBAN" do
    let!(:user) { create(:user, mandate: mandate, email: "peter.prospect@test.clark.de", source_data: {"adjust": {"network": "ing-diba"}}) }
    let!(:mandate) { create(:mandate,state: "accepted", created_at: 4.days.ago.beginning_of_day, encrypted_iban: nil) }

    it "sends the reminder when a mandate is accepted and the IBAN is not present" do
      expect(MandateMailer).to receive(:ing_iban_reminder).and_call_original
      expect do
        subject.ing_iban_reminder
      end.to change { mandate.documents.where(document_type: DocumentType.ing_iban_reminder).count }.by(1)
    end

    it "does not send out the reminder twice" do
      mandate.documents << create(:document, document_type: DocumentType.ing_iban_reminder)

      expect(MandateMailer).not_to receive(:ing_iban_reminder)
      expect do
        subject.ing_iban_reminder
      end.not_to change { mandate.documents.where(document_type: DocumentType.ing_iban_reminder).count }
    end
  end

  context "Mandate 1822direkt reminder email for IBAN" do
    let!(:user) {
      create(:user, mandate: mandate, email: "peter.prospect@test.clark.de", source_data: {
        "adjust": {
          "network": "1822direkt"
        }
      })
    }
    let!(:mandate) { create(:mandate, state: "accepted", created_at: 4.days.ago.beginning_of_day, encrypted_iban: nil) }

    it "sends the reminder when a mandate is accepted and the IBAN is not present" do
      expect(MandateMailer).to receive(:direkt_bank_iban_reminder).and_call_original
      expect do
        subject.direkt_bank_iban_reminder
      end.to change { mandate.documents.where(document_type: DocumentType.direkt_bank_iban_reminder).count }.by(1)
    end

    it "does not send out the reminder twice" do
      mandate.documents << create(:document, document_type: DocumentType.direkt_bank_iban_reminder)

      expect(MandateMailer).not_to receive(:direkt_bank_iban_reminder)
      expect do
        subject.direkt_bank_iban_reminder
      end.not_to change { mandate.documents.where(document_type: DocumentType.direkt_bank_iban_reminder).count }
    end
  end

  context "Portfolio Progress Mailer" do
    let!(:mandate) { create(:mandate, state: "accepted") }
    let!(:user) { create(:user, mandate: mandate) }
    let(:whitelisted_co) { create(:company, inquiry_blacklisted: false) }
    let(:inquiry_1) do
      create(:inquiry, mandate: mandate, state: "completed", company: whitelisted_co)
    end
    let(:inquiry_2) do
      create(:inquiry, mandate: mandate, state: "completed", company: whitelisted_co)
    end

    context "Portfolio in Progress Mail" do
      let(:messenger_provider) { OutboundChannels::Messenger::TransactionalMessenger }
      let(:messenger) { double(messenger_provider) }

      before do
        inquiry_1.inquiry_categories << create(:inquiry_category, inquiry: inquiry_1)
        inquiry_2.inquiry_categories << create(:inquiry_category, inquiry: inquiry_2)
        allow(messenger_provider).to receive(:new).and_return(messenger)
        allow(messenger).to receive(:send_message)
      end

      it "sends out the mail when an inquiry has been in the contacted state for 7 days" do
        expect(messenger_provider).to receive(:new).with(
          mandate,
          "portfolio_in_progress",
          hash_including(name: mandate.first_name, inquiry_id: inquiry_1.id),
          kind_of(Config::Options)
        )

        inquiry_1.update_attributes(state: "contacted", updated_at: 8.days.ago)

        expect(MandateMailer).to receive(:portfolio_in_progress).and_call_original
        expect { subject.portfolio_in_progress }.to change {
          mandate.documents.where(document_type: DocumentType.portfolio_in_progress).count
        }.from(0).to(1)
      end

      it "does not send an e-mail when the inquiry is blacklisted" do
        inquiry_1.company.update_attributes(inquiry_blacklisted: true)
        inquiry_2.company.update_attributes(inquiry_blacklisted: true)

        expect(MandateMailer).not_to receive(:portfolio_in_progress).and_call_original
        expect{ subject.portfolio_in_progress }.not_to change{
          mandate.documents.where(document_type: DocumentType.portfolio_in_progress).count
        }
      end

      it "does not contact the same customer twice if two inquiries are wating" do
        inquiry_1.update_attributes(state: "contacted", updated_at: 8.days.ago)
        inquiry_2.update_attributes(state: "contacted", updated_at: 10.days.ago)

        expect(MandateMailer).to receive(:portfolio_in_progress).once.and_call_original
        expect { subject.portfolio_in_progress }.to change {
          mandate.documents.where(document_type: DocumentType.portfolio_in_progress).count
        }.from(0).to(1)
      end

      it "does not send the mail twice" do
        inquiry_1.update_attributes(state: "contacted", updated_at: 8.days.ago)
        mandate.documents << create(:document, document_type: DocumentType.portfolio_in_progress)

        expect(MandateMailer).not_to receive(:portfolio_in_progress).and_call_original
        expect { subject.portfolio_in_progress }.not_to change{
          mandate.documents.where(document_type: DocumentType.portfolio_in_progress).count
        }
      end

      it "does not raise an exception if the e-mail is invalid" do
        inquiry_1.update_attributes(state: "contacted", updated_at: 8.days.ago)

        # The error happens in the Mandrill Gem, so we cannot emulate this here. Instead we throw the same exception
        # through a mock and see that the mailer handles it correctly
        expect(MandateMailer).to receive(:portfolio_in_progress).and_raise(NoMethodError, "undefined method `formatted' for #<Mail::UnstructuredField:0x...>")

        expect do
          subject.portfolio_in_progress
        end.not_to raise_error
      end

      it "does not send the mail if the inquiry category has documents already" do
        create(:document, documentable: inquiry_1.inquiry_categories.first)
        inquiry_1.update_attributes(state: "contacted", updated_at: 8.days.ago)
        inquiry_1.inquiry_categories << create(:inquiry_category, inquiry: inquiry_1)
        expect(MandateMailer).to receive(:portfolio_in_progress).and_call_original
        expect { subject.portfolio_in_progress }.to change {
          mandate.documents.where(document_type: DocumentType.portfolio_in_progress).count
        }.by(1)
      end

      it "send the mail if one of the inquiry categories has no documents" do
        create(:document, documentable: inquiry_1.inquiry_categories.first)
        inquiry_1.update_attributes(state: "contacted", updated_at: 8.days.ago)
        expect(MandateMailer).not_to receive(:portfolio_in_progress).and_call_original
        expect { subject.portfolio_in_progress }.not_to change {
          mandate.documents.where(document_type: DocumentType.portfolio_in_progress).count
        }
      end
    end

    context "Portfolio in Progress Mail (4 weeks)" do
      let(:messenger_provider) { OutboundChannels::Messenger::TransactionalMessenger }
      let(:messenger) { double(messenger_provider) }

      before do
        inquiry_1.inquiry_categories << create(:inquiry_category, inquiry: inquiry_1)
        inquiry_2.inquiry_categories << create(:inquiry_category, inquiry: inquiry_2)
        allow(messenger_provider).to receive(:new).and_return(messenger)
        allow(messenger).to receive(:send_message)
      end

      it "sends out the mail when an inquiry has been in the contacted state for 7 days" do
        inquiry_1.update_attributes(state: "contacted", updated_at: 5.weeks.ago)

        expect(MandateMailer).to receive(:portfolio_in_progress_4weeks).and_call_original
        expect{ subject.portfolio_in_progress_4weeks }.to change {
          mandate.documents.where(document_type: DocumentType.portfolio_in_progress_4weeks).count
        }.from(0).to(1)
      end

      it "does not send an e-mail when the inquiry is blacklisted" do
        inquiry_1.company.update_attributes(inquiry_blacklisted: true)
        inquiry_2.company.update_attributes(inquiry_blacklisted: true)

        expect(MandateMailer).not_to receive(:portfolio_in_progress_4weeks).and_call_original
        expect { subject.portfolio_in_progress_4weeks }.not_to change {
          mandate.documents.where(document_type: DocumentType.portfolio_in_progress_4weeks).count
        }
      end

      it "does not contact the same customer twice if two inquiries are wating" do
        inquiry_1.update_attributes(state: "contacted", updated_at: 5.weeks.ago)
        inquiry_2.update_attributes(state: "contacted", updated_at: 6.weeks.ago)

        expect(MandateMailer).to receive(:portfolio_in_progress_4weeks).once.and_call_original
        expect do
          subject.portfolio_in_progress_4weeks
        end.to change { mandate.documents.where(document_type: DocumentType.portfolio_in_progress_4weeks).count }.from(0).to(1)
      end

      it "does not send the mail twice" do
        inquiry_1.update_attributes(state: "contacted", updated_at: 5.weeks.ago)
        mandate.documents << create(:document, document_type: DocumentType.portfolio_in_progress_4weeks)

        expect(MandateMailer).not_to receive(:portfolio_in_progress_4weeks).and_call_original
        expect do
          subject.portfolio_in_progress_4weeks
        end.not_to change { mandate.documents.where(document_type: DocumentType.portfolio_in_progress_4weeks).count }
      end

      it "does not raise an exception if the e-mail is invalid" do
        inquiry_1.update_attributes(state: "contacted", updated_at: 5.weeks.ago)

        # The error happens in the Mandrill Gem, so we cannot emulate this here. Instead we throw the same exception
        # through a mock and see that the mailer handles it correctly
        expect(MandateMailer).to receive(:portfolio_in_progress_4weeks).and_raise(NoMethodError, "undefined method `formatted' for #<Mail::UnstructuredField:0x...>")

        expect do
          subject.portfolio_in_progress_4weeks
        end.not_to raise_error
      end
    end

    context "Portfolio in Progress Mail (16 weeks)" do
      let(:messenger_provider) { OutboundChannels::Messenger::TransactionalMessenger }
      let(:messenger) { double(messenger_provider) }

      before do
        inquiry_1.inquiry_categories << create(:inquiry_category, inquiry: inquiry_1)
        inquiry_2.inquiry_categories << create(:inquiry_category, inquiry: inquiry_2)
        allow(messenger_provider).to receive(:new).and_return(messenger)
        allow(messenger).to receive(:send_message)
      end

      it "sends out the mail when an inquiry has been in the contacted state for 7 days" do
        inquiry_1.update_attributes(state: "contacted", updated_at: 17.weeks.ago)

        expect(MandateMailer).to receive(:portfolio_in_progress_16weeks).and_call_original
        expect do
          subject.portfolio_in_progress_16weeks
        end.to change { mandate.documents.where(document_type: DocumentType.portfolio_in_progress_16weeks).count }.from(0).to(1)
      end

      it "does not send an e-mail when the inquiry is blacklisted" do
        inquiry_1.company.update_attributes(inquiry_blacklisted: true)
        inquiry_2.company.update_attributes(inquiry_blacklisted: true)

        expect(MandateMailer).not_to receive(:portfolio_in_progress_16weeks).and_call_original
        expect { subject.portfolio_in_progress_16weeks }.not_to change {
          mandate.documents.where(document_type: DocumentType.portfolio_in_progress_16weeks).count
        }
      end

      it "does not contact the same customer twice if two inquiries are wating" do
        inquiry_1.update_attributes(state: "contacted", updated_at: 17.weeks.ago)
        inquiry_2.update_attributes(state: "contacted", updated_at: 19.weeks.ago)

        expect(MandateMailer).to receive(:portfolio_in_progress_16weeks).once.and_call_original
        expect do
          subject.portfolio_in_progress_16weeks
        end.to change { mandate.documents.where(document_type: DocumentType.portfolio_in_progress_16weeks).count }.from(0).to(1)
      end

      it "does not send the mail twice" do
        inquiry_1.update_attributes(state: "contacted", updated_at: 17.weeks.ago)
        mandate.documents << create(:document, document_type: DocumentType.portfolio_in_progress_16weeks)

        expect(MandateMailer).not_to receive(:portfolio_in_progress_16weeks).and_call_original
        expect do
          subject.portfolio_in_progress_16weeks
        end.not_to change { mandate.documents.where(document_type: DocumentType.portfolio_in_progress_16weeks).count }
      end

      it "does not raise an exception if the e-mail is invalid" do
        inquiry_1.update_attributes(state: "contacted", updated_at: 17.weeks.ago)

        # The error happens in the Mandrill Gem, so we cannot emulate this here. Instead we throw the same exception
        # through a mock and see that the mailer handles it correctly
        expect(MandateMailer).to receive(:portfolio_in_progress_16weeks).and_raise(NoMethodError, "undefined method `formatted' for #<Mail::UnstructuredField:0x...>")

        expect do
          subject.portfolio_in_progress_16weeks
        end.not_to raise_error
      end
    end
  end

  context "Offer Mailer" do
    context "Offer Reminder 1, 2 and 3" do
      let!(:opportunity) { create(:opportunity_with_offer) }
      let!(:offer) { opportunity.offer }

      before do
        allow(PushService).to receive(:send_push_notification).and_return([double(Device, human_name: "some iPhone")])
        allow(Features).to receive(:active?).and_return true
        allow(Features).to receive(:active?).with(Features::MESSAGE_ONLY).and_return(false)
      end

      it "sends out Reminder #1 - 2 days after offer was sent" do
        offer.update_attributes(offered_on: 3.days.ago)

        expect(OfferMailer).to receive(:offer_reminder1).with(offer).and_call_original

        expect do
          subject.offer_reminders
        end.to change { offer.documents.where(document_type: DocumentType.offer_reminder1).count }.from(0).to(1)
      end

      it "sends out Reminder #1 - via Push" do
        allow(OfferMailer).to receive_message_chain("offer_reminder1.deliver_now")

        offer.mandate.user.devices << create(:device)
        offer.update(offered_on: 3.days.ago)

        expected_params = [
          offer.mandate,
          "offer_reminder1",
          offer.opportunity,
          { offer_id: offer.id, category: offer.category_name }
        ]
        expect(PushService).to receive(:send_transactional_push).with(*expected_params).and_call_original

        expect {
          perform_enqueued_jobs { subject.offer_reminders }
        }.to change { offer.mandate.interactions.count }.by(1)

        push_notification = offer.mandate.interactions.last
        expect(push_notification.title)
          .to eq(I18n.t("transactional_push.offer_reminder1.title", category: offer.category_name))
        expect(push_notification.content).to eq(I18n.t("transactional_push.offer_reminder1.content"))
        expect(push_notification.clark_url).to eq(I18n.t("transactional_push.offer_reminder1.url", offer_id: offer.id))
        expect(push_notification.section).to eq(I18n.t("transactional_push.offer_reminder1.section"))
        expect(push_notification.topic).to eq(offer.opportunity)
      end

      it "does not send out reminder #1 twice" do
        create(:business_event, entity: offer, action: "offer_reminder1")
        offer.update_attributes(offered_on: 3.days.ago)

        expect(OfferMailer).not_to receive(:offer_reminder1)
        subject.offer_reminders
      end

      it "sends out Reminder #2 - 7 days after offer was sent" do
        offer.update_attributes(offered_on: 8.days.ago)

        expect(OfferMailer).to receive(:offer_reminder2).with(offer).and_call_original

        expect do
          subject.offer_reminders
        end.to change {
          offer.documents.where(document_type: DocumentType.offer_reminder2).count
        }.from(0).to(1)
      end

      it "sends out Reminder #2 - via Push" do
        expect(OfferMailer).to receive_message_chain("offer_reminder2.deliver_now")

        offer.update(offered_on: 8.days.ago)
        offer.mandate.user.devices << create(:device)

        expected_params = [
          offer.mandate,
          "offer_reminder2",
          offer.opportunity,
          { offer_id: offer.id, category: offer.category_name }
        ]
        expect(PushService).to receive(:send_transactional_push).with(*expected_params).and_call_original

        expect {
          perform_enqueued_jobs { subject.offer_reminders }
        }.to change { offer.mandate.interactions.count }.by(2)

        push_notification = offer.mandate.interactions.find_by(type: Interaction::PushNotification.name)
        expect(push_notification.title)
          .to eq(I18n.t("transactional_push.offer_reminder2.title", category: offer.category_name))
        expect(push_notification.content).to eq(I18n.t("transactional_push.offer_reminder2.content"))
        expect(push_notification.clark_url).to eq(I18n.t("transactional_push.offer_reminder2.url", offer_id: offer.id))
        expect(push_notification.section).to eq(I18n.t("transactional_push.offer_reminder2.section"))
        expect(push_notification.topic).to eq(offer.opportunity)
      end

      it "does not send out reminder #2 twice" do
        create(:business_event, entity: offer, action: "offer_reminder2")
        offer.update_attributes(offered_on: 8.days.ago)

        expect(OfferMailer).not_to receive(:offer_reminder2)
        subject.offer_reminders
      end

      it "does not send out any reminders when the offer is expired" do
        offer.update_attributes(offered_on: 3.days.ago, state: "expired")

        expect(OfferMailer).not_to receive(:offer_reminder1)
        expect(OfferMailer).not_to receive(:offer_reminder2)

        subject.offer_reminders
      end

      it "does not send out any reminders when the offer is being expired on load" do
        offer.update(offered_on: 3.days.ago, valid_until: 1.day.ago)

        expect(OfferMailer).not_to receive(:offer_reminder1)
        expect(OfferMailer).not_to receive(:offer_reminder2)

        subject.offer_reminders
      end

      it "does not send out any reminders when the mandate was revoked" do
        offer.mandate.update_attributes(state: "revoked")
        offer.update_attributes(offered_on: 3.days.ago)

        expect(OfferMailer).not_to receive(:offer_reminder1)
        expect(OfferMailer).not_to receive(:offer_reminder2)

        subject.offer_reminders
      end

      it "does not send out any reminders when the offer was canceled" do
        offer.update_attributes(offered_on: 3.days.ago, state: "canceled")

        expect(OfferMailer).not_to receive(:offer_reminder1)
        expect(OfferMailer).not_to receive(:offer_reminder2)

        subject.offer_reminders
      end

      it "does not send out any reminders when the customer does not want to be contacted" do
        offer.mandate.user.update_attributes(subscriber: false)
        offer.update_attributes(offered_on: 3.days.ago)

        expect do
          subject.offer_reminders
        end.not_to change { offer.documents.count }
      end

      context "when an error occurs during dispatching of notifications" do
        before do
          distributor = double :distributor
          allow(OutboundChannels::DistributionChannels).to receive(:new).and_return distributor
          allow(distributor).to receive(:build_and_deliver).and_raise("wooops!")
        end

        it "creates a business event for reminder2 nevertheless" do
          offer.update_column(:offered_on, 8.days.ago)
          expect(BusinessEvent).to receive(:audit).with(offer, "offer_reminder2")
          subject.offer_reminders
        end

        it "creates a business event for reminder1 nevertheless" do
          offer.update_column(:offered_on, 2.days.ago)
          expect(BusinessEvent).to receive(:audit).with(offer, "offer_reminder1")
          subject.offer_reminders
        end
      end
    end

    context "IBAN Reminder" do
      let!(:mandate) { create(:mandate, iban: nil, user: create(:user)) }
      let!(:category) { create(:category, simple_checkout: true) }
      let!(:gkv_category) { create(:category_gkv) }
      let!(:product) { create(:product, mandate: mandate, state: "order_pending", plan: create(:plan, category: category)) }
      let!(:b_event) { create(:business_event, entity: product, action: "intend_to_order") }

      it "sends the reminder when the product was ordered 5 days ago and no IBAN is provided" do
        b_event.update(created_at: 6.days.ago)

        expect(OfferMailer).to receive(:offer_request_iban).with(mandate).and_call_original

        expect {
          subject.offer_iban_reminder
        }.to change {
          mandate.documents.where(document_type: DocumentType.offer_request_iban).count
        }.from(0).to(1)
      end

      it "does not send out the reminder when the user has an IBAN" do
        b_event.update_attributes(created_at: 6.days.ago)
        mandate.update_attributes(iban: "DE12500105170648489890")

        expect(OfferMailer).not_to receive(:offer_request_iban)

        expect do
          subject.offer_iban_reminder
        end.not_to change { mandate.documents.where(document_type: DocumentType.offer_request_iban).count }
      end

      it "does not send out the reminder twice" do
        b_event.update_attributes(created_at: 6.days.ago)
        mandate.documents << create(:document, document_type: DocumentType.offer_request_iban)

        expect(OfferMailer).not_to receive(:offer_request_iban)

        expect do
          subject.offer_iban_reminder
        end.not_to change { mandate.documents.where(document_type: DocumentType.offer_request_iban).count }
      end

      it "does not send out the reminder when the product was accepted too soon" do
        b_event.update_attributes(created_at: 3.days.ago)

        expect(OfferMailer).not_to receive(:offer_request_iban)

        expect do
          subject.offer_iban_reminder
        end.not_to change { mandate.documents.where(document_type: DocumentType.offer_request_iban).count }
      end

      it "does not send out the reminder when the there is no intend_to_order BusinessEvent" do
        b_event.destroy

        expect(OfferMailer).not_to receive(:offer_request_iban)

        expect do
          subject.offer_iban_reminder
        end.not_to change { mandate.documents.where(document_type: DocumentType.offer_request_iban).count }
      end

      context "when DE" do
        before { allow(Internationalization).to receive(:locale).and_return "de" }

        it "does not send out the reminder if it was gkv product" do
          gkv_product = create(:product, mandate: mandate, state: "order_pending", plan: create(:plan, category: gkv_category))
          business_event = create(:business_event, entity: gkv_product, action: "intend_to_order")
          business_event.update_attributes(created_at: 6.days.ago)
          expect(OfferMailer).not_to receive(:offer_request_iban)

          expect do
            subject.offer_iban_reminder
          end.not_to change { mandate.documents.where(document_type: DocumentType.offer_request_iban).count }
        end
      end
    end
  end

  context "MAM Credited Miles Mailer" do
    let!(:mandate) { create(:mandate, user: create(:user)) }
    let!(:mandate_no_miles) { create(:mandate, user: create(:user)) }
    let!(:miles_booking) { create(:loyalty_booking, mandate: mandate) }

    it "sends the miles when the user has credited miles already" do
      expect(MamMailer).to receive(:crediting_email).and_call_original

      expect do
        subject.mam_credit_miles
      end.to change { miles_booking.mandate.documents.where(document_type: DocumentType.crediting_email).count }.from(0).to(1)
    end

    it "do not send the e-mail twice" do
      expect(MamMailer).to receive(:crediting_email).and_call_original
      subject.mam_credit_miles

      expect do
        subject.mam_credit_miles
      end.not_to change { miles_booking.mandate.documents.where(document_type: DocumentType.crediting_email).count }
    end

    it "do not send the e-mail if I don't have miles" do
      expect(MamMailer).to receive(:crediting_email).and_call_original
      subject.mam_credit_miles

      expect do
        subject.mam_credit_miles
      end.not_to change { mandate_no_miles.documents.where(document_type: DocumentType.crediting_email).count }
    end
  end

  context "reminders for unread advices" do
    let(:address) { create(:address) }
    let(:admin) { create(:admin) }
    let(:product) { create(:product, mandate: nil) }

    let!(:mandate) { create(:mandate, user: create(:user), active_address: address) }
    let!(:mandate_two) { create(:mandate, user: create(:user), active_address: address) }
    let!(:mandate_three) { create(:mandate, user: create(:user), active_address: address) }
    let!(:mandate_four) { create(:mandate, user: create(:user), active_address: address) }
    let!(:mandate_five) { create(:mandate, user: create(:user), active_address: address) }
    let!(:mandate_six) { create(:mandate, user: create(:user), active_address: address) }
    let!(:mandate_seven) { create(:mandate, user: create(:user), active_address: address) }
    let!(:mandate_eight) { create(:mandate, user: create(:user), active_address: address) }

    before do
      create(:advice, mandate: mandate, created_at: 14.days.ago, admin: admin, product: product)
      create(:advice, mandate: mandate_two, created_at: 10.days.ago, admin: admin, product: product)
      create(:advice, mandate: mandate_three, created_at: 35.days.ago, admin: admin, product: product)
      create(:advice, mandate: mandate_four, created_at: 23.days.ago, admin: admin, product: product)
      create(:advice, mandate: mandate_five, created_at: 3.days.ago, admin: admin, product: product,
             metadata: {'identifier': "keeper_switcher"})
      create(:advice, mandate: mandate_six, created_at: 1.days.ago, admin: admin, product: product,
             metadata: {'identifier': "keeper_switcher"})
      create(:advice, mandate: mandate_seven, created_at: 5.days.ago, admin: admin, product: product,
             metadata: {'identifier': "keeper_switcher"})
      create(:advice, mandate: mandate_eight, created_at: 8.days.ago, admin: admin, product: product,
             metadata: {'identifier': "keeper_switcher"})
    end

    it "sends reminders" do
      # advice reminder email to mandates with unread advices for 14 days
      expect(AdviceMailer).to receive(:reminder_1).and_call_original
      expect do
        subject.advice_reminder
      end.to change { mandate.documents.where(document_type: DocumentType.reminder_1).count }.from(0).to(1)

      # does not send email to mandates with unread advice not equal to 14 days
      expect(mandate_two.documents.where(document_type: DocumentType.reminder_1).count).to eq 0

      # sends email to mandate with unread advice for 35 days
      expect(AdviceMailer).to receive(:reminder_advice_35_days).and_call_original
      expect do
        subject.advice_reminder_35days
      end.to change { mandate_three.documents.where(document_type: DocumentType.reminder_advice_35_days).count }.from(0).to(1)

      # does not send email to mandate with unread advice not equal to 35 days
      expect(mandate_four.documents.where(document_type: DocumentType.reminder_advice_35_days).count).to eq 0


      # sends email to mandate with unread reocurring advice for 2 days
      expect(AdviceMailer).to receive(:reminder_reoccuring_advice_2_days).and_call_original
      expect do
        subject.reoccuring_advice_reminder_2days
      end.to change { mandate_five.documents.where(document_type: DocumentType.reminder_reoccuring_advice_2_days).count }.from(0).to(1)

      # does not send an email to mandate with unread reocurring advice not equal to 2 days
      expect(mandate_six.documents.where(document_type: DocumentType.reminder_reoccuring_advice_2_days).count).to eq 0

      # sends email to mandate with unread reocurring advice for 5 days
      expect(AdviceMailer).to receive(:reminder_reoccuring_advice_5_day).and_call_original
      expect do
        subject.reoccuring_advice_reminder_5days
      end.to change { mandate_seven.documents.where(document_type: DocumentType.reminder_reoccuring_advice_5_day).count }.from(0).to(1)

      # it does not an send email to mandate with unread reocurring advice not equal to 5 days
      expect(mandate_eight.documents.where(document_type: DocumentType.reminder_reoccuring_advice_5_day).count).to eq 0
    end
  end


  describe ".number_one_rec_1day" do
    let!(:category) { create(:category_phv, life_aspect: ::Category.life_aspects["health"]) }
    let!(:questionnaire) { create(:bedarfscheck_questionnaire, category: category) }

    context "when customer who has finished questionnaire yesterday exists" do
      let!(:mandate) { create(:mandate, :accepted) }
      let!(:questionnaire_response) {
        create(
          :questionnaire_response,
          mandate: mandate,
          questionnaire: questionnaire,
          state: :analyzed,
          finished_at: 1.day.ago
        )
      }
      let!(:recommendation) do
        create(:recommendation, category: category, mandate: mandate)
      end

      context "when customer hasn't created product or enquiry" do
        it "does send No.1 recommendation reminder to customer" do
          expect(
            ::OutboundChannels::Messenger::TransactionalMessenger
          ).to receive(:number_1_recommendation_day1).with(
            mandate,
            recommendation.category
          )

          subject.number_one_rec_1day
        end
      end

      context "when customer has product for No.1 Recommendation" do
        let!(:product) { create(:product, mandate: mandate, category: category) }

        it "does not send No.1 recommendation reminder to customer" do
          expect(
            ::OutboundChannels::Messenger::TransactionalMessenger
          ).not_to receive(:number_1_recommendation_day1).with(
            mandate,
            recommendation.category
          )

          subject.number_one_rec_1day
        end
      end

      context "when customer has enquiry for No.1 Recommendation" do
        let!(:inquiry) { create(:inquiry, mandate: mandate) }
        let!(:inquiry_category) { create(:inquiry_category, category: category, inquiry: inquiry) }

        it "does not send No.1 recommendation reminder to customer" do
          expect(
            ::OutboundChannels::Messenger::TransactionalMessenger
          ).not_to receive(:number_1_recommendation_day1).with(
            mandate,
            recommendation.category
          )

          subject.number_one_rec_1day
        end
      end
    end
  end

  # Only testing logic for .number_one_rec_2day, dependent services are mocked.
  # Complete integration testing is done in .number_one_rec_1day context
  describe ".number_one_rec_2day" do
    let!(:mocked_time) { Time.current }
    let!(:recommendation) { build(:recommendation) }

    context "when customer who has finished questionnaire 2 days ago exists" do
      let(:number_one_recommendation_service) do
        double("NumberOneRecommendation", recommendations: [recommendation])
      end

      context "when customer hasn't created a product/enquiry for recommended category" do
        it "does send No.1 recommendation reminder to customer" do
          expect(
            ::OutboundChannels::Reminders::NumberOneRecommendation
          ).to receive(:new).with(
            starts: (mocked_time - 2.days).beginning_of_day,
            ends: (mocked_time - 2.days).end_of_day
          ).and_return(number_one_recommendation_service)
          expect(
            ::OutboundChannels::Messenger::TransactionalMessenger
          ).to receive(:number_1_recommendation_day2).with(
            recommendation.mandate,
            recommendation.category
          )

          Timecop.freeze(mocked_time) do
            subject.number_one_rec_2day
          end
        end
      end
    end
  end

  # Only testing logic for .number_one_rec_5day, dependent services are mocked.
  # Complete integration testing is done in .number_one_rec_1day context
  describe ".number_one_rec_2day" do
    let!(:mocked_time) { Time.current }
    let!(:recommendation) { build(:recommendation) }

    context "when customer who has finished questionnaire 5 days ago exists" do
      let(:number_one_recommendation_service) do
        double("NumberOneRecommendation", recommendations: [recommendation])
      end

      context "when customer hasn't created a product/enquiry for recommended category" do
        it "does send No.1 recommendation reminder to customer" do
          expect(
            ::OutboundChannels::Reminders::NumberOneRecommendation
          ).to receive(:new).with(
            starts: (mocked_time - 5.days).beginning_of_day,
            ends: (mocked_time - 5.days).end_of_day
          ).and_return(number_one_recommendation_service)
          expect(
            ::OutboundChannels::Messenger::TransactionalMessenger
          ).to receive(:number_1_recommendation_day5).with(
            recommendation.mandate,
            recommendation.category
          )

          Timecop.freeze(mocked_time) do
            subject.number_one_rec_5day
          end
        end
      end
    end
  end

  describe "#email_log" do
    let(:file_path) { "/" }
    let(:recipients) { ["user@example.com"] }
    let(:arguments) do
      {from: Settings.emails.service, to: recipients,
       subject: "CRON for Transactional Mails: #{file_path}", body: "siehe Attachment"}
    end
    let(:logger) { Logger.new("/dev/null") }
    let(:mail) { double.as_null_object }

    before do
      allow(ActionMailer::Base).to receive(:mail).with(arguments).and_return(mail)
      allow(mail).to receive(:deliver_now)
      allow(File).to receive(:read)

      described_class.new(logger).email_log(file_path, recipients)
    end

    it { expect(ActionMailer::Base).to have_received(:mail) }
    it { expect(mail).to have_received(:deliver_now) }
  end

  describe "#unread_message_3days_reminder" do
    let(:mandate) { create(:mandate) }
    let(:time) { Time.zone.now.middle_of_day }
    let!(:message1) { create(:unread_outgoing_message, mandate: mandate, created_at: (time - 3.days)) }
    let!(:message2) { create(:unread_outgoing_message, mandate: mandate, created_at: (time - 2.days)) }

    before { allow(Features).to receive(:active?).and_return true }

    it "should schedule SendUnreadMessageReminderJob for mandate" do
      expect { subject.unread_message_3days_reminder }.to \
        have_enqueued_job(TransactionalMailer::SendUnreadMessageReminderJob).with(mandate.id, 2)
    end
  end

  describe "#satisfaction_emails" do
    let(:repository) { object_double Domain::CustomerSurvey::RecipientsRepository.new, accepted_at: [mandate] }
    let(:mandate) { create :mandate, :accepted }

    before do
      allow(Domain::CustomerSurvey::RecipientsRepository).to receive(:new).and_return repository
      allow(Features).to receive(:active?).and_return true
    end

    context "when feature switcher is off" do
      before { allow(Features).to receive(:active?).with(Features::SATISFACTION_EMAIL).and_return false }

      it "does not send any emails" do
        expect(repository).not_to receive(:accepted_at)
        subject.satisfaction_emails
      end
    end

    context "when feature switcher is on" do
      let(:mail) { double :mail, subject: "Bla" }
      let(:mailer) { double :mailer, deliver_now: mail }

      before do
        allow(Features).to receive(:active?).with(Features::SATISFACTION_EMAIL).and_return true
        allow(CustomerSurveyMailer).to receive(:satisfaction).and_return mailer
      end

      it "sends the emails" do
        Timecop.freeze do
          expect(repository).to receive(:accepted_at).with(8.weeks.ago.beginning_of_day..8.weeks.ago.end_of_day)
          expect(CustomerSurveyMailer).to receive(:satisfaction).with(mandate)
          expect(mailer).to receive(:deliver_now)
          subject.satisfaction_emails
        end
      end

      it "generates a new interaction" do
        expect { subject.satisfaction_emails }.to change { mandate.interactions.count }.by(1)
        email = mandate.interactions.last
        expect(email).to be_kind_of Interaction::Email
        expect(email.direction).to eq "out"
        expect(email.topic).to eq mandate
      end
    end
  end
end
