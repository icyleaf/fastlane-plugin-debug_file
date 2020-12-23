# frozen_string_literal: true

require 'fastlane/action'
require_relative '../helper/debug_file_helper'

module Fastlane
  module Actions
    module SharedValues
      DF_DSYM_ZIP_PATH = :DF_DSYM_ZIP_PATH
    end

    class DsymAction < Action
      ARCHIVE_PATH = ::DebugFile::Runner::ARCHIVE_PATH
      OUTPUT_PATH = '.'

      def self.run(params)
        overwrite = params[:overwrite]

        archive_path = params[:archive_path]
        scheme = params[:scheme]
        runner = ::DebugFile::Runner.new({
          archive_path: archive_path,
          scheme: scheme
        })

        dsym = runner.latest_dsym
        unless dsym
          UI.user_error! "Not matched any archive [#{archive_path}] with scheme [#{scheme}]"
        end

        Fastlane::UI.success "Selected #{dsym[:name]} #{dsym[:release_version]} (#{dsym[:build]}) - #{dsym[:created_at]}"
        dsym[:machos].each do |macho|
          Fastlane::UI.message " • #{macho[:uuid]} (#{macho[:arch]})"
        end

        app_dsym_filename = File.basename(dsym[:dsym_path])
        output_file = File.join(params[:output_path], "#{app_dsym_filename}.zip")
        Helper::DebugFileHelper.determine_output_file(output_file, overwrite)

        archive_dsym_path = File.dirname(dsym[:dsym_path])
        extra_dsym = params[:extra_dsym] || []

        dsym_files = [app_dsym_filename].concat(extra_dsym).uniq
        dsym_files.each_with_index do |filename, i|
          path = File.join(archive_dsym_path, filename)
          if Dir.exist?(path)
            dsym_files[i] = path
          else
            dsym_files.delete_at(i)
          end
        end

        UI.message "Prepare #{dsym_files.size} dSYM file(s) compressing"
        UI.verbose dsym_files
        Helper::DebugFileHelper.compress(dsym_files, output_file)

        UI.success "Compressed dSYM file: #{output_file}"
        Helper::DebugFileHelper.store_shard_value SharedValues::DF_DSYM_ZIP_PATH, output_file
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
                                       default_value: Actions.lane_context[SharedValues::XCODEBUILD_ARCHIVE] || ::DebugFile::Runner::ARCHIVE_PATH,
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :scheme,
                                       env_name: 'DF_DSYM_SCHEME',
                                       description: 'The scheme name of app',
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :extra_dsym,
                                       env_name: 'DF_DSYM_EXTRA_DSYM',
                                       description: 'A set file name of dSYM',
                                       optional: true,
                                       default_value: [],
                                       type: Array),
          FastlaneCore::ConfigItem.new(key: :release_version,
                                       env_name: 'DF_DSYM_RELEASE_VERSION',
                                       description: 'Use the given release version of app',
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :build,
                                       env_name: 'DF_DSYM_BUILD',
                                       description: 'Use the given build version of app',
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :output_path,
                                       env_name: 'DF_DSYM_OUTPUT_PATH',
                                       description: "The output path of compressed dSYM file",
                                       default_value: OUTPUT_PATH,
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :overwrite,
                                       env_name: 'DF_DSYM_OVERWRITE',
                                       description: "Overwrite output compressed file if it existed",
                                       default_value: false,
                                       type: Boolean)
        ]
      end

      def self.example_code
        [
          'dsym',
          'dsym(
            archive_path: "~/Library/Developer/Xcode/Archives",
            overwrite: true,
            extra_dsym: [
              "AFNetworking.framework.dSYM",
              "Masonry.framework.dSYM"
            ]
          )'
        ]
      end

      def self.category
        :misc
      end

      def self.return_value
        String
      end

      def self.output
        [
          ['DF_DSYM_ZIP_PATH', 'the path of compressed proguard file']
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
