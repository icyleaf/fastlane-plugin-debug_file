require 'fastlane/action'
require_relative '../helper/debug_file_helper'

module Fastlane
  module Actions
    class AndroidDebugFileAction < Action
      def self.run(params)
        UI.message("The debug_file plugin is working!")
      end

      def self.description
        "debug_file"
      end

      def self.authors
        ["icyleaf"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        "Find and zip dSYM or proguard files"
      end

      def self.available_options
        [
          # FastlaneCore::ConfigItem.new(key: :your_option,
          #                         env_name: "DEBUG_FILE_YOUR_OPTION",
          #                      description: "A description of your option",
          #                         optional: false,
          #                             type: String)
        ]
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://docs.fastlane.tools/advanced/#control-configuration-by-lane-and-by-platform
        #
        # [:ios, :mac, :android].include?(platform)
        true
      end
    end
  end
end
