# frozen_string_literal: true

require "rails_helper"
require "extensions/array"

RSpec.describe Array do
  describe "execute_in_batches" do
    def generate_element
      Faker::Number.positive
    end

    def generate_array(uniq_elements_size)
      uniq_elements_size.times.map { generate_element } * Faker::Number.positive(2, 10)
    end

    def execute_in_batches_of(array, group_size, proc=proc { |param| param })
      array.execute_in_batches(group_size, proc)
    end

    it "operate on uniq version of passing array" do
      array = generate_array(1)
      number = array.first
      expect(execute_in_batches_of(array, 1).flatten).to eq([number])
    end

    it "operate on group size passing to it" do
      array = generate_array(2)
      expect(execute_in_batches_of(array, 1).length).to eq(2)
      expect(execute_in_batches_of(array, 2).length).to eq(1)
    end

    it "use proc passing to it on each group" do
      array = generate_array(3)
      proc = proc { |group| group.sum }
      expect(execute_in_batches_of(array, 3, proc)).to eq([array.uniq.sum])
    end
  end
end
