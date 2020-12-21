module BrowserHelpers
  def using_clark_app(&example_group_block)
    example_group_class = context "with the Clark App" do
      before do
        @current_driver = Capybara.current_driver
        Capybara.current_driver = :headless_chrome_ios_app
      end
      after do
        Capybara.current_driver = @current_driver
      end
    end

    example_group_class.class_eval(&example_group_block)
  end

  def using_android_app(&example_group_block)
    example_group_class = context "with the Clark App" do
      before do
        @current_driver = Capybara.current_driver
        Capybara.current_driver = :headless_chrome_android_app
      end
      after do
        Capybara.current_driver = @current_driver
      end
    end

    example_group_class.class_eval(&example_group_block)
  end

  def using_mobile_browser(&example_group_block)
    example_group_class = context "with the Clark App" do
      before do
        @current_driver = Capybara.current_driver
        Capybara.current_driver = :headless_chrome_mobile_ios_browser
      end
      after do
        Capybara.current_driver = @current_driver
      end
    end

    example_group_class.class_eval(&example_group_block)
  end

  def close_browser
    Capybara.current_session.driver.quit
  end
end
