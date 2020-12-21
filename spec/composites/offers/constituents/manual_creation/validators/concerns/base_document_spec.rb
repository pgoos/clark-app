# frozen_string_literal: true

require "rails_helper"
require "composites/offers/constituents/manual_creation/validators/concerns/base_document"

RSpec.describe Offers::Validators::BaseDocument do
  let(:contract) do
    clazz = Class.new(Dry::Validation::Contract) do
      include Offers::Validators::BaseDocument

      params do
        optional(:file)
      end

      rule(:file).validate(:file_extension)
    end
    clazz.new
  end

  %w[.jpg .JPG .jpeg .JPEG .png .PNG .pdf .PDF].each do |valid_postfix|
    it "is valid for the filename extension #{valid_postfix}" do
      file_name = "sample_file#{valid_postfix}"
      path = "some/path/#{file_name}"
      file = instance_double(File, path: path)
      carriage_return = "\r"
      head = <<~HTTP_HEAD
        Content-Disposition: form-data; name="file"; filename="#{file_name}"#{carriage_return}
        Content-Type: #{carriage_return}
        Content-Length: 3977#{carriage_return}
      HTTP_HEAD
      file_data = {
        "filename" => file_name,
        "type" => "",
        "name" => "file",
        "tempfile" => file,
        "head" => head
      }

      result = contract.call(file: file_data)
      expect(result.errors).to be_empty
    end
  end
end
