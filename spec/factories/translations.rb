# == Schema Information
#
# Table name: translations
#
#  id         :integer          not null, primary key
#  ident      :string
#  locales    :jsonb
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

FactoryBot.define do
  factory :translation do
    sequence :ident do |n|
      Digest::SHA1.hexdigest("dummy text #{n}")
    end
    locales {{en: "dummy text translation"}}
  end
end
