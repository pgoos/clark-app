require './spec/support/features/page_objects/page_object'

class ChangePasswordPage < PageObject

  def initialize(locale = I18n.locale)
    @locale = locale
    @path_to_page = "/#{locale}/password/edit"
    @path_to_manager = "/#{locale}/app/manager"
  end

  def visit_page
    visit @path_to_page
  end

  def visit_reset_pass(token)
    visit '/de/password/edit?reset_password_token=' + token
  end

  def fill_in_password(password, password2)
    fill_in 'user_password', with: password
    fill_in 'user_password_confirmation', with: password2
  end

  def click_cta
    find('.btn-primary').click
  end

  def expect_manager_page
    assert_current_path(@path_to_manager)
  end

  def expect_change_password_popup
    page.assert_selector('.modal__title')
    page.assert_selector('#user_password')
    page.assert_selector('#user_password_confirmation')
  end

  def expect_wrong_passsword_msg
    page.assert_selector('.ig__error-msg')
    page.assert_text('ist zu kurz')
  end

  def expect_password_mismatch_msg
    page.assert_text('stimmt nicht mit Passwort überein')
  end
end
