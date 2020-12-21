# frozen_string_literal: true

require "browsermob-proxy"

module Proxy
  class BrowserUpProxy
    class << self
      attr_reader :proxy, :record_har, :har_name

      # Run a proxy server, return if binary not found
      # @@param port [Integer] server port that should be used, defaults to 8080
      # @@param path_to_binary [String] defaults to root folder
      def start_server(port: 8080, path_to_binary: "browserup-proxy-2.1.1-SNAPSHOT/bin/browserup-proxy")
        current_thread = ENV["TEST_ENV_NUMBER"].to_i
        port += (current_thread * 5 + current_thread)
        puts "For current thread #{current_thread} port is #{port}"
        @server = BrowserMob::Proxy::Server.new(path_to_binary, { port: port })
        @server.start
        self
      end

      # Initialize and start a proxy, need server to be running
      # @record_har = should the traffic be recoded to HAR file?
      def create_proxy(record_har: true)
        if @server.nil?
          start_server
        end
        @record_har = record_har
        @proxy = @server.create_proxy
        self
      end

      # Creates a new instance of har log for running proxy
      # return if there is no proxy running or @record_har attribute is false
      # @param har_name [String] name of the har log, will be used to generate HAR file
      def create_new_har(har_name: nil, opts: {})
        return if @proxy.nil? || !@record_har
        @default_opts = {
          capture_headers: true,
          capture_content: false,
          capture_binary_content: false
        }
        @har_name = "#{har_name.nil? ? 'Cucumber_tests_HAR' : har_name.parameterize.underscore}" \
        "_#{Time.now.strftime('%Y-%m-%d-%H:%M:%S')}"
        @proxy.new_har(@default_opts.merge(opts)) if record_har
        @proxy.new_page(@har_name)
        self
      end

      # Saves traffic to HAR file
      # nothing will be saved if HAR log was not created
      # @param path [String] path for saving HAR file
      def save_har_to_file!(path=nil)
        return if @proxy.nil? || !@record_har
        har_log_file_path = path.nil? ? "#{@har_name}.har" : "#{path}/#{"#{@har_name}.har"}"
        @proxy.har.save_to(har_log_file_path)
        self
      end

      def get_proxy_address(*protocols)
        return nil if @proxy.nil?
        @proxy.selenium_proxy(*protocols)
      end

      def tear_down
        return if @server.nil?
        @server.stop
      end
    end
  end
end
