# frozen_string_literal: true

# Settings
# Constants
# Attribute Settings

# Plugins

RSpec.shared_examples "a model with normalized locale phone number field" do |phone_number_field, expected|
  before do
    subject.send("#{phone_number_field}=".to_sym, "01771661253")
    subject.save
  end

  it { expect(subject.send(phone_number_field)).to eq(expected) }
end

# Concerns
# Index
# State Machine

# Scopes

RSpec.shared_examples "a model providing a contains-scope on" do |*scopable_fields|
  scopable_fields.each do |scopable_field|
    describe ".by_#{scopable_field}_cont" do
      subject { described_class.send("by_#{scopable_field}_cont", query) }

      let(:factory) { described_class.name.downcase.to_sym }
      let(:query)   { "abcd" }

      before do
        @object1 = build(factory, scopable_field.to_sym => "xabcd")
        @object1.save(validate: false)

        @object2 = build(factory, scopable_field.to_sym => "xRTYd")
        @object2.save(validate: false)
      end

      it { expect(subject).to eq [@object1] }
    end
  end
end

# Associations
# Nested Attributes

# Validations

RSpec.shared_examples "a model requiring a password only for new records" do
  let(:model) { build ActiveModel::Naming.singular(described_class) }

  context "when new record" do
    it { expect(model).to validate_presence_of(:password) }
    it { expect(model.password_required?).to be true }
  end

  context "when persisted record" do
    before { allow(model).to receive(:new_record?).and_return(false) }

    context "when pasword field is not set" do
      before { model.password = nil }

      it { expect(model.password_required?).to be false }
      it { expect(model).not_to validate_presence_of(:password) }
    end

    context "when password field is set" do
      before { model.password = "password" }

      it { expect(model.password_required?).to be true }
    end

    context "when password confirmation field is set" do
      before { allow(model).to receive(:password_confirmation).and_return("pass") }

      it { expect(model.password_required?).to be true }
    end
  end
end

RSpec.shared_examples "a model with email validation on" do |*email_fields|
  email_fields.each do |email_field|
    let(:model) { build ActiveModel::Naming.singular(described_class) }

    it { expect(model).to allow_value("foo@clark.de").for(email_field) }

    ["test_user@example server.com", "foobar", "+464790909090"].each do |invalid_value|
      it { expect(model).not_to allow_value(invalid_value).for(email_field) }
    end
  end
end

RSpec.shared_examples "a model with localized phone number validation on" do |*phone_number_fields|
  phone_number_fields.each do |phone_number_field|
    describe "#{phone_number_field} field" do
      context "when default country code is DE" do
        before { stub_const("DEFAULT_COUNTRY_CODE", :de) }


        it_behaves_like(
          "a model with specific country phone number validation on",
          phone_number_field,
          %w[01771221632 +491771221632]
        )
      end

      context "when default country code is AT" do
        before { stub_const("DEFAULT_COUNTRY_CODE", :at) }

        it_behaves_like(
          "a model with specific country phone number validation on",
          phone_number_field,
          %w[01221331823 +431221331823]
        )
      end
    end
  end
end

RSpec.shared_examples "a model with specific country phone number validation on" do |phone_number_field, allowed_values|
  allowed_values.each do |allowed_value|
    it { expect(subject).to allow_value(allowed_value).for(phone_number_field) }
  end

  %w[234 3jjhkdsfh4 foobar].each do |invalid_value|
    it { expect(subject).not_to allow_value(invalid_value).for(phone_number_field) }
  end
end
# Callbacks

RSpec.shared_examples "a model with callbacks" do |point_in_time, callback, *method_names|
  method_names.each do |method_name|
    let(:model) { build ActiveModel::Naming.singular(described_class) }

    it do
      allow(model).to receive(method_name)
      # runs before-callbacks if block returns false /
      # runs before- and after-callbacks if block returns true
      model.run_callbacks(callback) { point_in_time == :after }

      expect(model).to have_received(method_name).once
    end
  end
end

# Delegates
# Instance Methods
# Class Methods
# Protected
# Private
