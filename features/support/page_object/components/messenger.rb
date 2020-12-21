# frozen_string_literal: true

require_relative "button.rb"
require_relative "file_upload.rb"
require_relative "icon.rb"
require_relative "input.rb"

module Components
  # COMPOSITE component
  # This component provides methods for the interaction with Messenger
  module Messenger
    include Components::Button
    include Components::FileUpload
    include Components::Icon
    include Components::Input

    # Method asserts that messenger is opened
    def assert_messenger_opened
      expect(page).to have_css(".cucumber-messenger-window")
    end

    # Method asserts that messenger contains a message from the admin side
    def verify_admin_message(message)
      last_admin_message = page.all("div.cucumber-message-admin p.cucumber-message-text").last
      expect(last_admin_message.shy_normalized_text(:all)).to eq(message)
    end

    # Method asserts that messenger contains a message from the user side
    def verify_user_message(message)
      last_user_message = page.all("div.cucumber-message-user p.cucumber-message-text").last
      expect(last_user_message.shy_normalized_text(:all)).to eq(message)
    end

    # Method asserts that messenger contains uploaded documents from the user side
    def verify_uploaded_documents(table)
      # assert uploaded documents icons quantity
      icons = find("section.cucumber-messenger-window").all("span.cucumber-document-icon")
      expect(icons.length).to be(table.rows.length), %(Uploaded documents icons quantity doesn't equal to the expected.
                                                       Expected #{table.rows.length}, but got #{icons.length})
      # assert uploaded documents list
      locator = "div.cucumber-message-user p.cucumber-document-title"
      expect(page.all(locator).map { |doc| doc.shy_normalized_text(:all) }).to eq(table.rows.flatten)
    end

    private

    # extend Components::Icon ------------------------------------------------------------------------------------------

    def click_messenger_icon(_)
      find(".cucumber-messenger-icon").click
      sleep 0.25
    end

    # extend Components::Button ----------------------------------------------------------------------------------------

    def click_messenger_send_button
      find(".cucumber-messenger-send-button").click
      sleep 0.25
    end

    # extend Components::Input -----------------------------------------------------------------------------------------

    def enter_value_into_messenger_input_field(message)
      find(".cucumber-messenger-input", visible: true).set(message)
      sleep 0.25
    end
  end
end
