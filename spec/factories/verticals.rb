# frozen_string_literal: true
# == Schema Information
#
# Table name: verticals
#
#  id         :integer          not null, primary key
#  state      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  ident      :string
#  name       :string
#


FactoryBot.define do
  factory :vertical do
    name { "Vertical Name" }
    sequence(:ident) do |n|
      [*"a".."z"].sample + SecureRandom.hex(4)[1..7] + n.to_s
    end

    trait :suhk do
      ident { "SUHK" }
    end

    trait :investment do
      name { "Investment" }
      ident { "INV" }
    end

    trait :state do
      name { "Gesetzliche Rentenversicherung" }
      ident { "GRV" }
    end

    trait :overall_personal do
      name { "Private Altersvorsorge" }
      ident { "PRV" }
    end

    trait :overall_corporate do
      name { "Betriebliche Altersvorsorge" }
      ident { "BRV" }
    end
  end
end
