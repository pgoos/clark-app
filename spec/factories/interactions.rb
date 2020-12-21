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


FactoryBot.define do
  factory :interaction do
    direction { "in" }
    metadata { {} }
    acknowledged { false }
    mandate

    factory :interaction_advice, class: Interaction::Advice do
      admin
      product
      content { "Something the admin says about the contract" }
      direction { "out" }
    end

    factory :interaction_adivce_reply, class: Interaction::AdviceReply do
      content { "Something the customer said" }
      direction { "in" }
    end

    factory :interaction_comment, class: Interaction::Comment do
      content { "Something a consultant says about the customer, but is kept internally" }
      direction { "internal" }
    end

    factory :interaction_email, class: Interaction::Email do
      metadata { {title: "Hello!!!"} }
      content { "<html><body>Is it me you're looking for?</body></html>" }
      direction { "out" }
    end

    factory :interaction_phone_call, class: Interaction::PhoneCall do
      content { "I have talked to the customer about his private liability insurance" }
      direction { "out" }
      admin

      factory :welcome_call do
        call_type { Interaction::PhoneCall.call_types[:mandate_welcome] }

        trait :successful do
          status { Interaction::PhoneCall::STATUS_REACHED }
        end

        trait :unsuccessful do
          status { Interaction::PhoneCall::STATUS_NOT_REACHED }
        end
      end

      factory :sales_warmup_call do
        call_type { Interaction::PhoneCall.call_types[:sales_warmup] }

        trait :successful do
          status { Interaction::PhoneCall::STATUS_REACHED }
        end

        trait :unsuccessful do
          status { Interaction::PhoneCall::STATUS_NOT_REACHED }
        end
      end
    end

    factory :interaction_push_notification, class: Interaction::PushNotification do
      metadata {
        {
          title:   "New Offer: PHV",
          devices: ["Apple iPhone 6s (9.1.0)", "Samsung Galaxy S6 (6.0)"]
        }
      }
      content { "We have a cheaper PHV for you, come check it out" }
      after(:build) { |push_notification|
        push_notification.class.skip_callback(:create, :before, :send_notification_to_devices,
                                              raise: false)
      }
    end

    factory :interaction_unread_automated_message, class: Interaction::Message do
      content { "Something the admin says about the contract" }
      direction { "out" }
      acknowledged { false }
      metadata do
        {created_by_robo: true}
      end
    end

    factory :interaction_unread_received_message, class: Interaction::Message do
      content { "Something the customer says" }
      direction { "in" }
      acknowledged { false }
    end

    factory :unread_outgoing_message, class: Interaction::Message do
      content { "Something" }
      direction { "out" }
      acknowledged { false }

      trait :reminded do
        metadata { {"reminded_at" => Time.zone.now} }
      end
    end

    factory :incoming_message, class: Interaction::Message do
      content { "Something the customer says" }
      direction { "in" }

      trait :unread do
        acknowledged { false }
      end

      trait :read do
        acknowledged { true }
      end
    end
  end
end
