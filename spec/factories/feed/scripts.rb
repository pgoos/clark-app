# frozen_string_literal: true

# == Schema Information
#
# Table name: feed_scripts
#
#  id                :integer          not null, primary key
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  script_content    :jsonb
#  is_default_script :boolean
#

FactoryBot.define do
  factory :feed_script, class: 'Feed::Script' do
    name = "testscript name"
    active = true
    listens_on = ["testscript"]
    conditions = []
    messages = [
        {
            "id" => "name1",
            "text" => "Welcome"
        },
        {
            "id" => "name2",
            "text" => "What?",
            "ctas" => [
                {
                    "link" => {
                        "text" => "goto here",
                        "href" => "link"
                    }
                },
                {
                    "button" => {
                        "text" => "jo!",
                        "event" => "event1"
                    }
                },
                {
                    "offer" => {
                        "icon" => "icon_name",
                        "href" => "link"
                    }
                }
            ]
        }
    ]
    script_content { ({
        "listens_on" => listens_on,
        "conditions" => conditions,
        "name" => name,
        "active" => active,
        "messages" => messages
    }) }
  end

end
