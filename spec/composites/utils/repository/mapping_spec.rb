# frozen_string_literal: true

require "rails_helper"
require "composites/utils/repository/mapping"

class TestClass
  def hello
    "world"
  end
end

class TestRepositoryClass
  extend Utils::Repository::Mapping::ClassMethods
  include Utils::Repository::Mapping

  map_attribute_with :hello, TestClass, :itself, ->(obj) { obj.hello }

  def wrap(entity)
    entity_attributes(entity)
  end
end

RSpec.describe Utils::Repository::Mapping do
  describe ".map_attribute_with" do
    it "returns value from lambda call" do
      test_wrap_result = TestRepositoryClass.new.wrap(TestClass.new)

      expect(test_wrap_result[:hello]).to eq "world"
    end
  end
end
