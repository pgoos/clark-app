# == Schema Information
#
# Table name: vouchers
#
#  id          :integer          not null, primary key
#  name        :string
#  code        :string
#  amount      :integer
#  valid_from  :datetime
#  valid_until :datetime
#  metadata    :jsonb
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

FactoryBot.define do
  factory :voucher do
    name { "Gutschein Kampagne" }
    code { SecureRandom.hex(3) }
    amount { 1 }
    valid_from { 5.days.ago }
    valid_until { 1.year.from_now }
    cpa_cents { 10_00 }
    metadata {
      {
        campaign: "campaign",
        source: "source",
        cpa_cents: cpa_cents
      }
    }
  end

  trait :iban do
    requires_iban { "1" }
  end
end
