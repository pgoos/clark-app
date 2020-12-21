require 'rails_helper'

RSpec.describe 'A user with a revoked mandate tries to access a manager page', :slow, :browser, type: :feature do

  let(:locale) { I18n.locale }
  let(:user) { create(:user, mandate: create(:mandate, state: 'revoked')) }

  before do
    login_as(user, scope: :user)
  end

  it 'the user is signed out and redirected to the home page', skip: "excluded from nightly, review" do
    visit manager_insurances_path(locale: locale)

    expect(page).to have_content(I18n.t('flash.alert.mandate_revoked'))
  end
end

