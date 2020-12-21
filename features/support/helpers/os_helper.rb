# frozen_string_literal: true

module Helpers
  # All interaction with OS (e.g. file access, process start, etc) in Cucumber tests should be defined here
  module OSHelper
    module_function

    # @param path [String] abs folder path
    # @return [Array<String>] sorted array of strings with abs paths of folders inside provided path
    def folders_array(path)
      Dir.glob("#{path}/*").select { |f| File.directory? f }.sort
    end

    def create_file_from_string_array(path, arr)
      File.open(path, "w") do |file|
        arr.each { |str| file.puts(str) }
      end
    end

    def copy_file(src, dest)
      FileUtils.cp(src, dest)
    end

    def read_file(path)
      File.read(path)
    end

    # Methods for providing an abs file path ---------------------------------------------------------------------------

    def file_path(*path)
      File.join(Dir.pwd, path)
    end

    def upload_file_path(file_name)
      file_path("features", "support", "upload_files", file_name)
    end
  end
end
