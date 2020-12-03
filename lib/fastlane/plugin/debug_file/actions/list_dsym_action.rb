# frozen_string_literal: true

require 'fastlane/action'
require_relative '../helper/debug_file_helper'

module Fastlane
  module Actions
    module SharedValues
      DF_DSYMS_LIST = :DF_DSYMS_LIST
    end

    class ListDsymAction < Action
      def self.run(params)
        archive_path = params[:archive_path]
        scheme = params[:scheme]
        Fastlane::UI.verbose "Finding #{scheme || 'all' } xcarchive in #{archive_path} ..."

        runner = ::DebugFile::Runner.new({
          archive_path: archive_path,
          scheme: scheme
        })

        dsyms = runner.list_dsym

        Fastlane::UI.success "Found #{dsyms.size} dSYM files"
        dsyms.each do |dsym|
          Fastlane::UI.success "• #{dsym[:name]} #{dsym[:release_version]} (#{dsym[:build]}) - #{dsym[:created_at]}"
          dsym[:machos].each do |macho|
            Fastlane::UI.message "  #{macho[:uuid]} (#{macho[:arch]})"
          end
        end

        Helper::DebugFileHelper.store_shard_value SharedValues::DF_DSYMS_LIST, dsyms

        dsyms
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Find and generate iOS/MacOS dSYM file(s) to zip file'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :archive_path,
                                       env_name: 'DF_DSYM_ARCHIVE_PATH',
                                       description: 'The archive path of xcode',
                                       type: String,
                                       default_value: Actions.lane_context[SharedValues::XCODEBUILD_ARCHIVE] || ::DebugFile::Runner::ARCHIVE_PATH,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :scheme,
                                       env_name: 'DF_DSYM_SCHEME',
                                       description: 'The scheme name of app',
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :release_version,
                                       env_name: 'DF_DSYM_RELEASE_VERSION',
                                       description: 'Use the given release version of app',
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :build,
                                       env_name: 'DF_DSYM_BUILD',
                                       description: 'Use the given build version of app',
                                       optional: true,
                                       type: String)
        ]
      end

      def self.example_code
        [
          'list_dsym',
          'list_dsym(
            archive_path: "~/Library/Developer/Xcode/Archives",
            scheme: "AppName"
          )'
        ]
      end

      def self.category
        :misc
      end

      def self.return_value
        Array
      end

      def self.output
        [
          ['DF_DSYMS_LIST', 'the array of dSYMs metadata']
        ]
      end

      def self.authors
        ['icyleaf']
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end
    end
  end
end
