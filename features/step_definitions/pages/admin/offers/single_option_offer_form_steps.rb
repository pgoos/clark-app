# frozen_string_literal: true

When(/^admin fills out ([^"]*) section with following values$/) do |section, table|
  case section.downcase
  when "angezeigte leistungen"
    single_option_offer_edit_form.fill_in_coverage_features_section(table.hashes)
  when "angezeigte dokumente"
    single_option_offer_edit_form.fill_in_documents_section(table.rows)
  else
    raise NotImplementedError, "Section #{section} is not implemented."
  end
end

# Context --------------------------------------------------------------------------------------------------------------

private

# @return [AdminPages::SingleOptionOfferFormEdit]
def single_option_offer_edit_form
  PageContextManager.assert_context(AdminPages::SingleOptionOfferFormEdit)
  PageContextManager.context
end
