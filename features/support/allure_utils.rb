# frozen_string_literal: true

require_relative "helpers/os_helper.rb"
require_relative "page_context_manager.rb"

# Module provides several methods required for the Allure report generation
module AllureUtils
  module_function

  # https://docs.qameta.io/allure/#_environment
  def create_env_properties_file
    return if allure_output_folder.nil?
    return if allure_output_folder&.include?("parallel_runtime_cucumber.log")

    context = TestContextManager.instance
    env_properties = %W[CUCUMBER_TARGET_URL=#{context.target_url} CAPYBARA_DRIVER=#{context.driver}]

    file_path = Helpers::OSHelper.file_path(allure_output_folder, "environment.properties")
    Helpers::OSHelper.create_file_from_string_array(file_path, env_properties)
  end

  # https://docs.qameta.io/allure/#_categories_2
  def copy_categories_json_file
    return if allure_output_folder.nil?

    Helpers::OSHelper.copy_file(Helpers::OSHelper.upload_file_path("categories.json"),
                                Helpers::OSHelper.file_path(allure_output_folder))
  end

  def allure_output_folder
    out_index = ARGV.find_index("--out")
    return nil if out_index.nil?
    ARGV[out_index + 1]
  end
end
