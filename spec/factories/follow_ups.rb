# == Schema Information
#
# Table name: follow_ups
#
#  id           :integer          not null, primary key
#  item_id      :integer
#  item_type    :string
#  admin_id     :integer
#  due_date     :datetime
#  comment      :string
#  acknowledged :boolean          default(FALSE)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

FactoryBot.define do
  factory :follow_up do
    due_date { 1.day.from_now }

    trait :skip_validation do
      to_create { |instance| instance.save(validate: false) }
    end

    trait :phone_call do
      interaction_type { "phone_call" }
    end

    trait :message do
      interaction_type { "message" }
    end

    trait :acknowledged do
      acknowledged { true }
    end

    trait :unacknowledged do
      acknowledged { false }
    end
  end
end
