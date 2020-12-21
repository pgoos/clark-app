# frozen_string_literal: true

class FakeSTMPMailService
  def initialize(connection)
    @connection = connection
  end

  def get_all_inbox_messages(email)
    @connection.execute_http_request(email)
  end
end
