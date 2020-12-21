# == Schema Information
#
# Table name: product_partner_data
#
#  id              :integer          not null, primary key
#  data            :jsonb
#  product_id      :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  state           :string
#  reason_to_defer :string
#

FactoryBot.define do
  factory :product_partner_datum do
    data do
      {
        gender: 'male',
        birthdate: '1.1.1990',
        premium: ValueTypes::Money.new(110.00, 'EUR'),
        replacement_premium: ValueTypes::Money.new(89.00, 'EUR'),
        premium_period: 'year',
        'VU' => 'tarif name',
      }
    end
    product
  end
end

