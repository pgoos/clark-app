# frozen_string_literal: true

RSpec.shared_context "ensure locale is de" do
  around do |example|
    locale = I18n.locale
    I18n.locale = :de
    example.run
    I18n.locale = locale
  end
end
