# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Offer state machine", type: :model do
  let(:offer) { build(:offer) }

  before do
    # We do not want to send out mails in arbitrary actions ...
    # Those tests that care about the mails will have an expect on the mailer
    %i[
      offer_available_top_cover_and_price
      new_product_offer_available
      offer_available_top_price
      offer_available_top_cover
      offer_thank_you
    ].each do |message|
      allow(OfferMailer).to receive(message).with(offer).and_return(ActionMailer::Base::NullMail.new)
    end

    settings = Config::Options.new(
      push_with_sms_fallback: true,
      offer_generated: Config::Options.new(
        email: true,
        sms: false,
        push: true,
        push_with_sms_fallback: false,
        messenger: true,
        mailer_options: { class: OfferMailer.name },
        deliver_now: true,
        messenger_options: {
          class: OutboundChannels::Messenger::TransactionalMessenger.name,
          method: :offer_available
        }
      )
    )
    allow(Settings).to receive(:transactional_messaging).and_return settings

    allow(Comfy::Cms::Site)
      .to receive(:find_by).with(identifier: "de").and_return Comfy::Cms::Site.new(hostname: "0.0.0.0:3000")

    allow(OutboundChannels::Mocks::FakeRemotePushClient)
      .to receive_messages(publish: nil, delete_endpoint: nil, create_platform_endpoint: nil)

    allow(offer).to receive(:vvg_attached_to_offer).and_return(true)
  end

  # State Machine
  context "state machine" do
    context "initial state (in_creation)" do
      let(:offer) { build(:offer, opportunity: opportunity, mandate: mandate) }
      let(:opportunity) { build(:opportunity, mandate: mandate, admin: nil) }
      let(:mandate) { build(:mandate) }

      it "is created in in_creation state" do
        expect(Offer.new).to be_in_creation
      end

      it "can be transitioned to the active state" do
        expect(offer.can_send_offer?).to eq true
      end

      it "can be canceled" do
        expect(offer.can_cancel?).to eq true
      end

      it "cannot be transitioned to other states" do
        expect(offer.can_reject?).to eq false
        expect(offer.can_accept?).to eq false
        expect(offer.can_expire?).to eq false
      end
    end

    context "active state" do
      let(:opportunity) { build(:opportunity, mandate: mandate, category: category, admin: nil) }
      let(:mandate) { build(:mandate) }
      let(:category) { build(:category) }
      let(:offer) { build(:offer, state: :active, opportunity: opportunity, mandate: mandate) }

      it "can be rejected" do
        expect(offer.can_reject?).to eq true
      end

      it "can be accepted" do
        expect(offer.can_accept?).to eq true
      end

      it "can be canceled" do
        expect(offer.can_cancel?).to eq true
      end

      it "can be expired" do
        expect(offer.can_expire?).to eq true
      end

      it "cannot be transitioned to other states" do
        expect(offer.can_send_offer?).to eq false
      end
    end

    %w[expired canceled].each do |state|
      context "#{state} state" do
        let(:offer) { build(:offer, state: state, opportunity: nil, mandate: nil) }

        it "cannot be transitioned to other states" do
          expect(offer.can_send_offer?).to eq false
          expect(offer.can_accept?).to eq false
          expect(offer.can_expire?).to eq false
          expect(offer.can_cancel?).to eq false
        end
      end
    end

    context "accepted state" do
      let(:offer) { build(:offer, state: :accepted, opportunity: nil, mandate: nil) }

      it "cannot be transitioned to other states" do
        expect(offer.can_send_offer?).to eq false
        expect(offer.can_accept?).to eq false
        expect(offer.can_expire?).to eq false
        expect(offer.can_cancel?).to eq false
      end
    end

    context "transition hooks" do
      context "before_transition to active" do
        let(:opportunity) { build(:opportunity, mandate: nil, category: category, admin: nil) }
        let(:offer) { build(:offer, opportunity: nil, mandate: nil) }
        let(:mandate) { build(:mandate) }
        let(:category) { build(:category) }

        before do
          allow(offer).to receive(:mandate).and_return(mandate)
          allow(opportunity).to receive(:mandate).and_return(mandate)
          allow(offer).to receive(:opportunity).and_return(opportunity)
        end

        it "calls activate_offer on event send_offer" do
          expect(offer).to receive(:activate_offer)
          offer.send_offer
        end

        context "activate_offer method" do
          context "high margin offer" do
            let(:category) { create(:category, :high_margin) }

            it "does not set the offered_on" do
              expect { offer.send(:activate_offer, nil) }.not_to change(offer, :valid_until)
            end
          end

          context "medium margin offer" do
            let(:category) { create(:category, :medium_margin) }

            it "does not set the offered_on" do
              expect { offer.send(:activate_offer, nil) }.not_to change(offer, :valid_until)
            end
          end

          context "low margin offer" do
            let(:category) { create(:category, :low_margin) }

            it "sets the offered_on date to the current date" do
              Timecop.freeze do
                expect { offer.send(:activate_offer, nil) }
                  .to change(offer, :valid_until).from(nil).to(30.days.from_now.end_of_day)
              end
            end
          end

          context "high margin gkv offer" do
            let(:category) { create(:category_gkv, :high_margin) }

            it "sets the offered_on date to the current date" do
              Timecop.freeze do
                expect { offer.send(:activate_offer, nil) }
                  .to change(offer, :valid_until).from(nil).to(30.days.from_now.end_of_day)
              end
            end
          end

          it "sets the offered_on date to the current date" do
            Timecop.freeze do
              expect { offer.send(:activate_offer, nil) }
                .to change(offer, :offered_on).from(nil).to(DateTime.current)
            end
          end

          it "sets the valid_until date to 30 days from now" do
            Timecop.freeze do
              expect { offer.send(:activate_offer, nil) }
                .to change(offer, :valid_until).from(nil).to(30.days.from_now.end_of_day)
            end
          end

          it "transitions opportunity to offer phase" do
            offer.send(:activate_offer, nil)
            expect(offer.opportunity).to be_offer_phase
          end

          it "transitions opportunity to offer phase from created" do
            offer.opportunity = build(:opportunity, state: :created, mandate: nil, admin: nil)
            offer.send_offer
            expect(offer.opportunity).to be_offer_phase
          end
        end
      end

      context "after_transition to active" do
        let(:mandate) { build(:mandate) }
        let(:category) { build(:category) }
        let(:offer) { build(:offer, opportunity: nil, mandate: nil) }
        let(:opportunity) do
          double(:opportunity, state: :initiation_phase, mandate: mandate, marked_for_destruction?: false,
                               admin: double(:admin))
        end

        before do
          allow(offer).to receive(:opportunity).and_return(opportunity)
          allow(offer).to receive(:category).and_return(category)
          allow(offer).to receive(:determine_offer_type).and_return(:offer_available_top_price)
          allow(Interaction::SentOffer).to receive(:create)
        end

        it "calls activate_offer on event send_offer" do
          expect(offer).to receive(:send_available_email)
          offer.send_offer
        end

        context "gkv offer" do
          let(:category) { create(:category_gkv) }

          it "does not send offer available email" do
            expect(offer).not_to receive(:send_offer_messages_generic)
            offer.send_offer!
          end
        end

        context "low margin offer" do
          let(:category) { create(:category, :low_margin) }

          it "does not send offer available email" do
            expect(offer).not_to receive(:send_offer_messages_generic)
            offer.send_offer!
          end
        end

        context "medium margin offer" do
          let(:category) { create(:category, :medium_margin) }

          it "sends offer available email" do
            expect(offer).to receive(:send_offer_messages_generic)
            offer.send_offer!
          end
        end

        context "high margin offer" do
          let(:category) { create(:category, :high_margin) }

          it "sends offer available email" do
            expect(offer).to receive(:send_offer_messages_generic)
            offer.send_offer!
          end
        end
      end

      context "send_available_email" do
        let(:opportunity) { create(:opportunity, state: :initiation_phase, admin: nil) }
        let(:mandate) { opportunity.mandate }
        let(:offer) do
          create(
            :offer,
            opportunity:   opportunity,
            mandate:       mandate,
            offer_options: [build(:offer_option, recommended: true)]
          )
        end

        context "when is a instant offer" do
          let(:offer_rule) { create(:offer_rule) }
          let(:offer) do
            create(
              :offer,
              opportunity:   opportunity,
              mandate:       mandate,
              offer_rule:    offer_rule,
              offer_options: [build(:offer_option, recommended: true)]
            )
          end

          it "does not send out transactional message" do
            expect(OutboundChannels::Messenger::TransactionalMessenger).not_to receive(:offer_available)

            offer.send_offer
          end
        end

        context "when is not a instant offer" do
          it "creates the offer-sent interaction" do
            expect(Interaction::SentOffer).to receive(:create).with(
              hash_including(topic: offer.opportunity, mandate: mandate, offer_id: offer.id)
            ).once
            offer.send_offer
          end

          context "send_available_email method" do
            let(:admin) { build(:admin) }
            let(:mandate) { build(:mandate) }
            let(:old_product) { build(:product, mandate: mandate, plan: nil, company: nil) }
            let(:product) { build(:product, mandate: nil, company: build(:company), plan: nil) }
            let(:recommended_option) { build(:offer_option, recommended: true, product: product) }
            let(:opportunity) do
              build(:opportunity, state: :initiation_phase, old_product: old_product, mandate: mandate, admin: admin)
            end
            let(:offer) { build(:offer, opportunity: nil, mandate: nil, offer_options: [recommended_option]) }
            let(:push_notification_hash) do
              {
                title: I18n.t("transactional_push.new_product_offer_available.title", category: offer.category_name),
                content: I18n.t("transactional_push.new_product_offer_available.content"),
                clark_url: I18n.t("transactional_push.new_product_offer_available.url", offer_id: offer.id),
                section: I18n.t("transactional_push.product_updated.section"),
                topic: new_opportunity,
                mandate: mandate,
                admin: new_opportunity.admin
              }
            end

            before do
              allow(offer).to receive(:mandate).and_return(mandate)
              allow(offer).to receive(:opportunity).and_return(opportunity)
              allow(offer).to receive(:recommended_option).and_return(recommended_option)
              allow(offer).to receive(:id).and_return(789)
              allow(Admin).to receive_message_chain(:count, :zero?).and_return(false)
              allow(Admin).to receive(:bot).and_return(admin)
            end

            context "new_product_offer_available" do
              let(:new_opportunity) do
                build(:opportunity, old_product: nil, mandate: offer.mandate, offer: offer, admin: admin)
              end
              let(:push_notification) { Interaction::PushNotification.new(push_notification_hash) }

              before do
                allow(offer).to receive(:opportunity).and_return(new_opportunity)
                allow(Interaction::SentOffer).to receive(:create)
              end

              it "sends out mail" do
                expect(OfferMailer).to receive(:new_product_offer_available)
                  .with(offer).and_return(ActionMailer::Base::NullMail.new)
                offer.send(:send_available_email, nil)
              end

              it "sends out push" do
                device             = build(:device, permissions: { push_enabled: true })
                offer.mandate.user = build(:user, devices: [device])
                offer.mandate.save!

                expect(push_notification).to receive("devices=")
                allow_any_instance_of(Interaction::Message).to receive(:pushed_to_messenger).and_return(nil)
                expect(push_notification).to receive(:save).and_return(true)
                allow(Interaction::PushNotification).to receive(:create!).with(
                  push_notification_hash
                ).and_return(push_notification)

                offer.send(:send_available_email, nil)
              end

              it "sends out transactional message" do
                device             = build(:device)
                offer.mandate.user = build(:user, devices: [device])

                expect(OutboundChannels::Messenger::TransactionalMessenger)
                  .to receive(:offer_available)

                offer.send(:send_available_email, nil)
              end

              it "will not fail over all, if push fails" do
                offer = create(:offer)
                offer.mandate.user = build(:user, devices: [build(:device, permissions: { push_enabled: true })])
                offer.mandate.save!

                expect(OutboundChannels::Messenger::TransactionalMessenger).to receive(:offer_available).and_return(nil)

                expect(OfferMailer)
                  .to receive(:new_product_offer_available).with(offer).and_return(ActionMailer::Base::NullMail.new)

                expect(PushService).to receive(:send_push_notification).and_throw(Aws::SNS::Errors::InvalidParameter)

                offer.send(:send_available_email, nil)
              end
            end

            context "offer_available_top_price" do
              let(:recommended_option) { build(:price_option, recommended: true) }

              before do
                offer.offer_options.each { |option| option.recommended = false }
                offer.offer_options << recommended_option
                allow(offer).to receive(:recommended_option).and_return(recommended_option)
              end

              it "sends out email" do
                expect(OfferMailer)
                  .to receive(:offer_available_top_price).with(offer).and_return(ActionMailer::Base::NullMail.new)

                offer.send(:send_available_email, nil)
              end

              it "sends out push && messenger message" do
                device             = build(:device, permissions: { push_enabled: true })
                offer.mandate.user = build(:user, devices: [device])
                offer.mandate.save!

                allow_any_instance_of(Interaction::Message).to receive(:pushed_to_messenger).and_return(nil)

                expect { offer.send(:send_available_email, nil) }
                  .to change { offer.mandate.interactions.count }.by(3)

                push_notification = offer.mandate.interactions.where(type: Interaction::PushNotification.name).last

                expect(push_notification.title)
                  .to eq(I18n.t("transactional_push.offer_available_top_price.title"))

                expect(push_notification.content)
                  .to eq(I18n.t("transactional_push.offer_available_top_price.content"))

                expect(push_notification.clark_url)
                  .to eq(I18n.t("transactional_push.offer_available_top_price.url", offer_id: offer.id))

                expect(push_notification.section)
                  .to eq(I18n.t("transactional_push.offer_available_top_price.section"))

                expect(push_notification.topic).to eq(offer.opportunity)
                expect(push_notification.devices).to be_present
              end
            end

            context "offer_available_top_cover" do
              let(:product) { build(:product, mandate: nil, company: build(:company), plan: nil) }
              let(:recommended_option) { build(:cover_option, recommended: true, product: product) }
              let(:push_notification) { Interaction::PushNotification.new(push_notification_hash) }
              let(:push_notification_hash) do
                {
                  title:     I18n.t("transactional_push.offer_available_top_cover.title"),
                  content:   I18n.t("transactional_push.offer_available_top_cover.content"),
                  clark_url: I18n.t("transactional_push.offer_available_top_cover.url", offer_id: offer.id),
                  section:   I18n.t("transactional_push.offer_available_top_cover.section"),
                  topic:     opportunity,
                  mandate:   mandate,
                  admin:     opportunity.admin
                }
              end

              before do
                offer.offer_options.each { |option| option.recommended = false }
                offer.offer_options << recommended_option
                allow(offer).to receive(:recommended_option).and_return(recommended_option)
                allow(Interaction::SentOffer).to receive(:create)
              end

              it "sends out mail" do
                expect(OfferMailer).to receive(:offer_available_top_cover)
                  .with(offer).and_return(ActionMailer::Base::NullMail.new)
                offer.send(:send_available_email, nil)
              end

              it "sends out push && messenger message" do
                allow(OfferMailer).to receive(:offer_available_top_cover_and_price)
                  .with(offer).and_return(ActionMailer::Base::NullMail.new)

                offer.mandate.user = build(:user, devices: [build(:device, permissions: { push_enabled: true })])
                offer.mandate.save

                expect(Interaction::SentOffer).to receive(:create).once

                expect_any_instance_of(Interaction::PushNotification).to receive("devices=").at_least(1)
                expect_any_instance_of(Interaction::PushNotification).to receive(:save).and_return(true)
                expect(OutboundChannels::Messenger::TransactionalMessenger).to receive(:offer_available).and_return(nil)

                expect { offer.send(:send_available_email, nil) }
                  .to change { offer.mandate.interactions.count }.by(1)
              end
            end

            context "offer_available_top_cover_and_price" do
              before do
                offer.offer_options << build(:offer_option, recommended: true)
              end

              it "sends out mail" do
                expect(OfferMailer).to receive(:offer_available_top_cover_and_price)
                  .with(offer).and_return(ActionMailer::Base::NullMail.new)

                offer.send(:send_available_email, nil)
              end

              it "sends out push" do
                offer.mandate.user = build(:user, devices: [build(:device, permissions: { push_enabled: true })])
                offer.mandate.save!

                allow_any_instance_of(Interaction::Message).to receive(:pushed_to_messenger).and_return(nil)
                expect { offer.send(:send_available_email, nil) }
                  .to change { offer.mandate.interactions.count }.by(3)

                push_notification = offer.mandate.interactions.where(type: Interaction::PushNotification.name).last

                expect(push_notification.title)
                  .to eq(I18n.t("transactional_push.offer_available_top_cover_and_price.title"))

                expect(push_notification.content)
                  .to eq(I18n.t("transactional_push.offer_available_top_cover_and_price.content"))

                expect(push_notification.clark_url)
                  .to eq(I18n.t("transactional_push.offer_available_top_cover_and_price.url", offer_id: offer.id))

                expect(push_notification.section)
                  .to eq(I18n.t("transactional_push.offer_available_top_cover_and_price.section"))

                expect(push_notification.topic).to eq(offer.opportunity)

                expect(push_notification.devices).to be_present
              end
            end
          end
        end
      end

      context "after_transition to rejected, expired or canceled" do
        let(:offer) do
          build(:offer, state: :active, opportunity: build(:opportunity, mandate: nil, admin: nil),
                        mandate: build(:mandate))
        end

        %w[cancel reject expire].each do |event|
          it "calls reject_offer on event '#{event}'" do
            expect(offer).to receive(:reject_offer)

            offer.send(event.to_sym)
          end
        end

        context "reject_offer method" do
          let(:product) { build(:product, plan: nil, mandate: nil, company: nil) }

          it "cancels offered products" do
            build(:offer_option, offer: offer, recommended: true, product: product)
            build(:price_option, offer: offer)

            offer.send(:reject_offer, nil)

            expect(offer.offered_products).to all(be_canceled)
          end

          it "does not cancel the old product" do
            create(:old_product_option, offer: offer, recommended: true)
            offer.send(:reject_offer, nil)
            expect(offer.old_product).to be_details_available
          end

          it "sets opportunity to be lost" do
            offer.opportunity = build(:opportunity, state: "offer_phase", mandate: build(:mandate), admin: nil)
            offer.send(:reject_offer, nil)
            expect(offer.opportunity).to be_lost
          end
        end
      end

      context "after_transition to accepted" do
        let(:category) { build(:category) }
        let(:mandate) { build(:mandate) }
        let(:opportunity) { build(:opportunity, mandate: mandate, admin: nil) }
        let(:offer) { build(:offer, state: :active, mandate: nil, admin: nil) }
        let(:option1) do
          build(:offer_option, offer: offer, recommended: true,
                               product: build(:product, mandate: nil, plan: nil, company: nil))
        end
        let(:option2) do
          build(:price_option, offer: offer, product: build(:product, mandate: nil, plan: nil, company: nil))
        end
        let(:option3) do
          build(:old_product_option, offer: offer, product: build(:product, state: "details_available", mandate: nil,
                                     plan: nil, company: nil))
        end
        let(:options) { [option1, option2, option3] }

        before do
          allow(offer).to receive(:mandate).and_return(mandate)
        end

        it "calls accept_offer on event accept" do
          expect(offer).to receive(:accept_offer)
          offer.accept
        end

        it "calls send_thank_you_email on event accept" do
          expect(offer).to receive(:send_thank_you_email)
          offer.accept
        end

        context "send_thank_you_email method" do
          it "sends out the thank you mail when the category is simple checkout" do
            offer.opportunity = build(
              :opportunity, category: build(:category, :low_margin, simple_checkout: true)
            )

            expect(OfferMailer)
              .to receive(:offer_thank_you).with(offer).and_return(ActionMailer::Base::NullMail.new)

            offer.send(:send_thank_you_email, double(args: []))
          end

          it "does not send out the mail for complex checkout" do
            offer.opportunity = build(
              :opportunity,
              category: build(:category, simple_checkout: false)
            )

            expect(OfferMailer).not_to receive(:offer_thank_you)

            offer.send(:send_thank_you_email, double(args: []))
          end
        end

        context "accept_offer method" do
          before do
            allow(options).to receive(:includes).and_return(options)
            allow(offer).to receive(:offer_options).and_return(options)
          end

          it "cancels all offered products and marks old product for termination if no product is given" do
            expect(option1.product).to receive(:cancel!)
            expect(option2.product).to receive(:cancel!)
            expect(option3.product).to receive(:intend_to_terminate!)

            offer.send(:accept_offer, double(args: []))
          end

          it "marks the accepted option to be ordered (with product), old product for termination and cancels other offered products" do
            allow(option1.product).to receive(:update)

            expect(option1.product).to receive(:intend_to_order!)
            expect(option2.product).to receive(:cancel!)
            expect(option3.product).to receive(:intend_to_terminate!)

            offer.send(:accept_offer, double(args: [option1.product]))
          end

          it "marks the accepted option to be ordered (with option), old product for termination and cancels other offered products" do
            allow(option1.product).to receive(:update)

            expect(option1.product).to receive(:intend_to_order!)
            expect(option2.product).to receive(:cancel!)
            expect(option3.product).to receive(:intend_to_terminate!)

            offer.send(:accept_offer, double(args: [option1]))
          end

          it "marks the accepted option to be ordered (with product), leave the old product if already terminated and cancels other offered products" do
            allow(option1.product).to receive(:update)
            option3.product.state = :terminated

            expect(option1.product).to receive(:intend_to_order!)
            expect(option2.product).to receive(:cancel!)
            expect(option3.product).to be_terminated

            offer.send(:accept_offer, double(args: [option1.product]))
          end

          it "marks the accepted option to be ordered (with product), leave the old product if already in termination process and cancels other offered products" do
            allow(option1.product).to receive(:update)
            option3.product.state = :termination_pending

            expect(option1.product).to receive(:intend_to_order!)
            expect(option2.product).to receive(:cancel!)
            expect(option3.product).to be_termination_pending

            offer.send(:accept_offer, double(args: [option1.product]))
          end
        end
      end
    end
  end
end
