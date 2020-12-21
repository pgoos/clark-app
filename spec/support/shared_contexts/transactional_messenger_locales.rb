# frozen_string_literal: true

RSpec.shared_context "with transactional messenger locales" do
  let(:message) { I18n.t("messenger.#{content_key}.content", options) }
  let(:cta_link) { I18n.t("messenger.#{content_key}.cta_link", options) }
  let(:cta_text) { I18n.t("messenger.#{content_key}.cta_text", options) }
  let(:cta_section) { I18n.t("messenger.#{content_key}.cta_section", options) }

  before do
    @current_locale = I18n.locale
    I18n.locale = :de
  end

  after do
    I18n.locale = @current_locale
  end
end
