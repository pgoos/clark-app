# frozen_string_literal: true

# == Schema Information
#
# Table name: miles_more_booking_tables
#
#  id         :integer          not null, primary key
#  valid_from :date
#  rules      :jsonb            not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

FactoryBot.define do
  factory :miles_more_booking_table do
    valid_from { "2017-03-02" }
    rules { "{}" }

    trait :with_rules_normal do
      rules {
        {
          "1" => {"ftl" => 0, "sen" => 0, "base" => 0},
          "2" => {"ftl" => 2000, "sen" => 3000, "base" => 1000},
          "3" => {"ftl" => 500, "sen" => 500, "base" => 500},
          "4" => {"ftl" => 500, "sen" => 500, "base" => 500},
          "5" => {"ftl" => 500, "sen" => 500, "base" => 500},
          "6" => {"ftl" => 1000, "sen" => 1000, "base" => 1000},
          "7" => {"ftl" => 1000, "sen" => 1000, "base" => 1000},
          "8" => {"ftl" => 1000, "sen" => 1000, "base" => 1000},
          "9" => {"ftl" => 2000, "sen" => 2000, "base" => 2000},
          "10" => {"ftl" => 2500, "sen" => 2500, "base" => 2500}
        }
      }
    end

    trait :with_rules_count_first_product do
      rules {
        {
          "1" => {"ftl" => 50, "sen" => 100, "base" => 150},
          "2" => {"ftl" => 2000, "sen" => 3000, "base" => 1000},
          "3" => {"ftl" => 500, "sen" => 500, "base" => 500},
          "4" => {"ftl" => 500, "sen" => 500, "base" => 500},
          "5" => {"ftl" => 500, "sen" => 500, "base" => 500},
          "6" => {"ftl" => 1000, "sen" => 1000, "base" => 1000},
          "7" => {"ftl" => 1000, "sen" => 1000, "base" => 1000},
          "8" => {"ftl" => 1000, "sen" => 1000, "base" => 1000},
          "9" => {"ftl" => 2000, "sen" => 2000, "base" => 2000},
          "10" => {"ftl" => 2500, "sen" => 2500, "base" => 2500}
        }
      }
    end

    trait :with_rules_extra_1000 do
      rules {
        {
          "1" => {"ftl" => 0, "sen" => 0, "base" => 0},
          "2" => {"ftl" => 3000, "sen" => 4000, "base" => 2000},
          "3" => {"ftl" => 500, "sen" => 500, "base" => 500},
          "4" => {"ftl" => 500, "sen" => 500, "base" => 500},
          "5" => {"ftl" => 500, "sen" => 500, "base" => 500},
          "6" => {"ftl" => 1000, "sen" => 1000, "base" => 1000},
          "7" => {"ftl" => 1000, "sen" => 1000, "base" => 1000},
          "8" => {"ftl" => 1000, "sen" => 1000, "base" => 1000},
          "9" => {"ftl" => 2000, "sen" => 2000, "base" => 2000},
          "10" => {"ftl" => 2500, "sen" => 2500, "base" => 2500}
        }
      }
    end

    trait :with_rules_mam_base do
      rules {
        {
          "1" => {"ftl" => 0, "sen" => 0, "base" => 0},
          "2" => {"ftl" => 3000, "sen" => 4000, "base" => 2000},
          "3" => {"ftl" => 1000, "sen" => 1000, "base" => 1000},
          "4" => {"ftl" => 1000, "sen" => 1000, "base" => 1000},
          "5" => {"ftl" => 1000, "sen" => 1000, "base" => 1000},
          "6" => {"ftl" => 1000, "sen" => 1000, "base" => 1000},
          "7" => {"ftl" => 1000, "sen" => 1000, "base" => 1000},
          "8" => {"ftl" => 1000, "sen" => 1000, "base" => 1000},
          "9" => {"ftl" => 1000, "sen" => 1000, "base" => 1000},
          "10" => {"ftl" => 1000, "sen" => 1000, "base" => 1000}
        }
      }
    end
  end
end
