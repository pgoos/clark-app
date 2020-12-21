# frozen_string_literal: true

require_relative "repository/repository.rb"
require_relative "page_object/pages/generic_page.rb"

# import all page object files
Dir["#{File.dirname(__FILE__)}/page_object/pages/**/*.rb"].each { |f| load(f) }

# This module stores, updates and provides information about current Page Context
# This module should be considered as a Singleton
# Page context must be switched every time when a page, opened in a browser,  is being changed
# Page context must be switched ONLY within
#                         `Then(/^(?:user|admin) is on the (.*) page$/) do |path_name|` step
module PageContextManager
  extend self

  # @param repository [Repository::Repository]
  def init(repository)
    @repository   = repository
    @page_context = GenericPage.new
  end

  def context
    @page_context
  end

  # methods checks if current context is an instance of expected context or includes it
  # @raise [RuntimeError]
  # @param expected Component or Page class
  def assert_context(expected)
    return if context.is_a?(expected) || context.class < expected
    raise "Current Page Context '#{context}' isn't equal to and doesn't include the expected #{expected}"
  end

  def switch_context(to)
    target_class  = "#{context_group(to)}::#{to.tr('-', ' ').split.map(&:capitalize).join('')}"
    @page_context = Object.const_defined?(target_class) ? Object.const_get(target_class).new : GenericPage.new
  end

  private

  def context_group(to)
    return "AppPages"   if @repository[to].start_with?("/de/app")
    return "AdminPages" if @repository[to].start_with?("/de/admin")
    return "CMSPages"
  end
end
