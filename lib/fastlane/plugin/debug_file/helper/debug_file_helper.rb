require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class DebugFileHelper
      def self.compress(src_files, desc_file)
        require 'zip'

        output_path = File.dirname(desc_file)
        FileUtils.mkdir_p output_path unless Dir.exist?(output_path)
        ::Zip::File.open(desc_file, ::Zip::File::CREATE) do |zipfile|
          src_files.each do |file|
            zipfile.add File.basename(file), file
          end
        end
      end

      def self.determine_output_file(output_file, overwrite)
        if File.exist?(output_file)
          if overwrite
            FileUtils.rm_f output_file
          else
            UI.user_error! "Compressed file was existed: #{output_file}"
          end
        end
      end

      def self.store_shard_value(key, value)
        Actions.lane_context[key] = value
        ENV[key.to_s] = value
      end
    end
  end
end
