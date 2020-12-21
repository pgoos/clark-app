require 'rails_helper'
require './spec/support/features/page_objects/account/edit_user_account_page.rb'

RSpec.describe 'A user changes password and email', :slow, :browser, type: :feature do

  let(:user) { create(:user) }
  let(:edit_user_account_page) { EditUserAccountPage.new }

  before do
    login_as(user, scope: :user)
  end

  it 'when the form is completed' do
    edit_user_account_page.visit_page
    edit_user_account_page.fill_form
    edit_user_account_page.submit_form
    edit_user_account_page.expect_success
  end

  it 'when the form is not completed' do
    edit_user_account_page.visit_page
    edit_user_account_page.blank_form
    edit_user_account_page.submit_form
    edit_user_account_page.expect_failure
  end
end
