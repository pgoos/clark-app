# frozen_string_literal: true


class LetterOpenerSmsService
  def initialize
    @letter_opener_path = Helpers::OSHelper.file_path("tmp", "letter_opener")
  end

  def get_verification_token(phone_number)
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop do
        Helpers::OSHelper.folders_array(@letter_opener_path).reverse_each do |folder|
          token_info = parse_file(File.join(folder, "plain.html"))
          return token_info.token_value if token_info.valid?(phone_number)
        end
        sleep(5)
      end
    end
  end

  private

  TokenInfo = Struct.new(:phone, :token_value) do
    def valid?(phone_number)
      phone == phone_number && !token_value.nil?
    end
  end

  # @return [TokenInfo]
  def parse_file(file_path)
    token_info = TokenInfo.new
    File.readlines(file_path).each do |line|
      if token_info.phone.nil?
        phone = line.match(/(?<=Phone\sNumber:\s\+49)\d+/)
        token_info.phone = phone[0] unless phone.nil?
      end
      if token_info.token_value.nil?
        token = line.match(/(?<=lautet\s)\d{4}/)
        token_info.token_value = token[0] unless token.nil?
      end
    end
    token_info
  end
end
