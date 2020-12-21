# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Reports::Marketing::AbortedQuestionnaireCsv do
  it_behaves_like "a csv report", "admin.marketing.reports.aborted_questionnaire"
end
