# frozen_string_literal: true

require 'fastlane/action'
require_relative '../helper/debug_file_helper'

module Fastlane
  module Actions
    module SharedValues
      DF_DSYM_ZIP_PATH = :DF_DSYM_ZIP_PATH
    end

    class DsymAction < Action
      ARCHIVE_PATH = File.expand_path('~/Library/Developer/Xcode/Archives')
      OUTPUT_PATH = '.'

      def self.run(params)
        archive_path = File.expand_path(params[:archive_path])
        scheme = params[:scheme]
        overwrite = params[:overwrite]

        app_dsym_filename = "#{scheme}.app.dsym"

        output_path = params[:output_path]
        output_file = File.join(output_path, "#{app_dsym_filename}.zip")

        Helper::DebugFileHelper.determine_output_file(output_file, overwrite)

        archive_dsym_path = last_created_dsym(scheme, archive_path)
        if archive_dsym_path && !Dir.exist?(archive_dsym_path)
          UI.user_error! "Not matched any archive with scheme: #{scheme}"
        end

        xcarchive_file = File.basename(File.dirname(archive_dsym_path))
        xcarchive_info_file = File.join(File.expand_path('../', archive_dsym_path), 'Info.plist')
        xcarchive_info = Helper::DebugFileHelper.xcarchive_metadata(xcarchive_info_file)
        release_version, build_version, created_at = version_info(xcarchive_info)
        UI.success "Selected dSYM archive: #{release_version} (#{build_version}) [#{xcarchive_file}] #{created_at}"

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
        UI.success "Prepare #{dsym_files.size} dSYM file(s) compressing"
        Helper::DebugFileHelper.compress(dsym_files, output_file)

        UI.success "Compressed dSYM file: #{output_file}"
        Helper::DebugFileHelper.store_shard_value SharedValues::DF_DSYM_ZIP_PATH, output_file
      end

      def self.last_created_dsym(scheme, archive_path)
        info_path = File.join(archive_path, '**', '*.xcarchive', 'Info.plist')
        matched_paths = []

        UI.verbose "Finding #{scheme} xcarchive in #{archive_path} ..."
        Dir.glob(info_path) do |path|
          info = Helper::DebugFileHelper.xcarchive_metadata(path)
          name = Helper::DebugFileHelper.fetch_key(info, 'Name')
          if scheme == name
            xcarchive = File.basename(File.dirname(path))
            release_version, build_version, created_at = version_info(info)
            UI.verbose " => #{release_version} (#{build_version}) [#{xcarchive}] was created at #{created_at}"

            matched_paths << path
          end
        end

        return if matched_paths.empty?

        UI.verbose "Found #{matched_paths.size} matched dSYM archive(s) of #{scheme}"
        last_created_path = matched_paths.size == 1 ? matched_paths.first : matched_paths.max_by { |p| File.stat(p).mtime }
        File.join(File.dirname(last_created_path), 'dSYMs')
      end
      private_class_method :last_created_dsym

      def self.version_info(info)
        release_version = Helper::DebugFileHelper.fetch_key(info, 'ApplicationProperties', 'CFBundleShortVersionString')
        build = Helper::DebugFileHelper.fetch_key(info, 'ApplicationProperties', 'CFBundleVersion')
        created_at = Helper::DebugFileHelper.fetch_key(info, 'CreationDate')

        [release_version, build, created_at]
      end
      private_class_method :version_info

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
                                       default_value: Actions.lane_context[SharedValues::XCODEBUILD_ARCHIVE] || ARCHIVE_PATH,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :scheme,
                                       env_name: 'DF_DSYM_SCHEME',
                                       description: 'The scheme name of app',
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
