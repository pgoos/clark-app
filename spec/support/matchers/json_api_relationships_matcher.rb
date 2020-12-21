# frozen_string_literal: true

RSpec::Matchers.define :have_has_one_relationship do |id, type, included_attributes={}|
  match do |json_response|
    id = id.to_s
    relationship_data = json_response["data"]["relationships"][type]["data"]
    included_object = json_response["included"]&.find { |e| e["id"] == id && e["type"] == type }

    expect(relationship_data["id"]).to eq(id)
    expect(relationship_data["type"]).to eq(type)
    expect(included_object).not_to be(nil)
    expect(included_object["attributes"]).to include(included_attributes)
  end
end
