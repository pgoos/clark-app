module TestHost
  class << self
    def test_host
      '127.0.0.1'
    end

    def test_port
      8200
    end

    def host_and_port
      "#{test_host}:#{test_port}"
    end
  end
end