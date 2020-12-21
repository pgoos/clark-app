# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "an inquiry mail delegator" do |delegator_dir|
  context "delegates" do
    it "should instantiate all delegates" do

      # first find all senders
      dir = Rails.root.join("lib", "lifters", "domain", "inquiries", delegator_dir)
      glob = dir.join("*.rb")
      file_names = Dir.glob(glob)

      # load the classes
      classes = file_names.map do |file_name|
        # extract the class name:
        postfix = file_name[(dir.to_s.length + 1)..file_name.length]
        snake_case_name = postfix[0..(postfix.length - 4)]

        "#{described_class.name}::#{snake_case_name.camelize}".constantize
      end

      senders = described_class.new.instance_variable_get(:@senders)

      # Did we find senders?
      expect(senders.size).not_to eq(0)

      # Now let's check, if all senders were registered.
      classes.each do |clazz|
        # DropInsuranceRequest is a bit like a nil object to this process:
        next if clazz == Domain::Inquiries::InitialContacts::DropInsuranceRequest
        expect(senders[clazz.ident]).to be_a(clazz)
      end
    end
  end
end
