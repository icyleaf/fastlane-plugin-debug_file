require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class DebugFileHelper
      def self.compress(src_files, desc_file)
        require 'zip'

        FileUtils.mkdir_p output_path unless Dir.exist?(File.basename(desc_file))
        ::Zip::File.open(desc_file, ::Zip::File::CREATE) do |zipfile|
          src_files.each do |file|
            zipfile.add file[:name], file[:path]
          end
        end
      end
    end
  end
end
