# frozen_string_literal: true

require "rails_helper"

RSpec.describe InvitationMailer, :integration, type: :mailer do
  let(:email) { "test@test.clark.de" }
  let(:referral_code) { "sample_referral_code" }
  let(:mandate) { create(:mandate) }
  let(:referrer) { create(:user, referral_code: referral_code, mandate: mandate) }
  let(:mail) { InvitationMailer.invite(email, referrer) }
  let(:document_type) { DocumentType.invite }
  let(:documentable) { mandate }

  it { expect(mail.from).to eq([Settings.emails.service]) }
  it { expect(mail.to).to eq([email]) }

  include_examples "checks mail rendering"
  include_examples "tracks document and mandate in ahoy email"
end
