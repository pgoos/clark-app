# frozen_string_literal: true

module SettingsHelpers
  def save_settings(*paths)
    @saved_settings ||= {}

    paths.each do |path|
      tokens = path.split(/\./)
      node = Settings
      option = tokens.pop

      tokens.each { |token| node = node.send(token) }

      @saved_settings[path] = node.send(option)
    end
  end

  def restore_settings
    return unless @saved_settings

    @saved_settings.each do |path, value|
      tokens = path.split(/\./)
      node = Settings
      option = "#{tokens.pop}="

      tokens.each { |token| node = node.send(token) }
      node.send(option, value)
    end

    @saved_settings = {}
  end
end
