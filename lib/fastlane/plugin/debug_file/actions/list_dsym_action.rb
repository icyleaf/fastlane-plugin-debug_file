# frozen_string_literal: true

require 'fastlane/action'
require_relative '../helper/debug_file_helper'

module Fastlane
  module Actions
    module SharedValues
      DF_DSYMS_LIST = :DF_DSYMS_LIST
    end

    class ListDsymAction < Action
      ARCHIVE_PATH = File.expand_path('~/Library/Developer/Xcode/Archives')

      def self.run(params)
        archive_path = File.expand_path(params[:archive_path])
        dsyms = search_dsym(archive_path, params[:scheme])

        UI.success "Found #{dsyms.size} dSYM files"
        dsyms.each do |dsym|
          UI.success "• #{dsym[:name]} #{dsym[:release_version]} (#{dsym[:build]})"
          dsym[:machos].each do |macho|
            UI.message "  #{macho[:uuid]} (#{macho[:arch]})"
          end
        end
      end

      def self.search_dsym(archive_path, search_scheme = nil)
        info_path = File.join(archive_path, '**', '*.xcarchive', 'Info.plist')
        matched_paths = []

        UI.verbose "Finding #{search_scheme} xcarchive in #{archive_path} ..."

        obj = []
        Dir.glob(info_path) do |path|
          info = Helper::DebugFileHelper.xcarchive_metadata(path)
          name = Helper::DebugFileHelper.fetch_key(info, 'Name')
          next unless search_scheme.to_s.empty? || search_scheme == scheme_name

          release_version = Helper::DebugFileHelper.fetch_key(info, 'ApplicationProperties', 'CFBundleShortVersionString')
          build = Helper::DebugFileHelper.fetch_key(info, 'ApplicationProperties', 'CFBundleVersion')
          dsym_path = Dir.glob(File.join(File.dirname(path), 'dSYMs', "#{name}.app.dSYM", '**', '*', name)).first
          created_at = Helper::DebugFileHelper.fetch_key(info, 'CreationDate')

          machos = []
          Helper::DebugFileHelper.macho_metadata(dsym_path).each do |macho|
            machos << {
              arch: macho.cpusubtype,
              uuid: macho[:LC_UUID][0].uuid_string
            }
          end

          item = {
            root_path: File.basename(File.dirname(path)),
            dsym_path: dsym_path,
            machos: machos,
            info: info,
            name: name,
            release_version: release_version,
            build: build,
            created_at: created_at,
          }

          yield item if block_given?

          obj << item
        end

        obj
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
                                       default_value: Actions.lane_context[SharedValues::XCODEBUILD_ARCHIVE] || ARCHIVE_PATH,
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
