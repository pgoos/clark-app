# frozen_string_literal: true

require "rails_helper"

# TODO: Create a better way to test the generator
RSpec.describe "Mailer code generator", :slow do
  it "should add method to mailer" do
    mail_identifier = "mail_identifier"

    obj = StarterMailer.new # just random mailer from project
    expect(obj.methods).not_to include(mail_identifier.to_sym)

    p `bundle exec rails generate cms_mail_template StarterMailer/mail_identifier --title=some_title --skip-migration`

    # since Rails app was already loaded before new method was added then we need to reload mailer
    Object.send(:remove_const, :StarterMailer)
    load Rails.root.join("app", "mailers", "starter_mailer.rb")

    obj = StarterMailer.new
    expect(obj.methods).to include(mail_identifier.to_sym)
  end
end
