# frozen_string_literal: true

RSpec.shared_examples "a plain text message" do
  it "should render the subject with I18n" do
    rendered_subject = message.subject
    expect(rendered_subject).not_to include(subject_key)
  end

  it "should render the subject and replace interpolations" do
    rendered_subject = message.subject
    expect(rendered_subject).not_to include("%{")
  end

  it "should render the body with I18n" do
    rendered_body = message.body
    expect(rendered_body).not_to include(body_key)
  end

  it "should render the body and replace interpolations" do
    rendered_body = message.body
    expect(rendered_body).not_to include("%{")
  end
end
