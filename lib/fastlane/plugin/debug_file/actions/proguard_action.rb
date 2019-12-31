# frozen_string_literal: true

require 'fastlane/action'
require_relative '../helper/debug_file_helper'
require 'zip'

module Fastlane
  module Actions
    module SharedValues
      PROGUARDS = :PROGUARDS
    end

    MATCHES_FILES = {
      manifest: {
        name: 'AndroidManifest.xml',
        path: 'build/intermediates/manifests/full'
      },
      mapping: {
        name: 'mapping.txt',
        path: 'build/outputs/mapping'
      },
      symbol: {
        name: 'R.txt',
        path: 'build/intermediates/symbols'
      }
    }

    RELEASE_TYPE = 'release'
    APP_PATH = 'app'
    OUTPUT_PATH = File.join('build', 'outputs', 'debug_files')

    class ProguardAction < Action
      def self.run(params)
        app_path = File.expand_path(params[:app_path])
        puts app_path
        build_type = params[:build_type]

        src_files = find_proguard_files(app_path, build_type)
        UI.user_error! 'No found proguard file' if src_files.empty?

        print_table(src_files)

        desc_path = File.join(app_path, OUTPUT_PATH)
        Dir.mkdir desc_path unless Dir.exist?(desc_path)

        desc_file = File.join(desc_path, zip_filename(build_type))
        ::Zip::File.open(desc_file, ::Zip::File::CREATE) do |zipfile|
          src_files.each do |file|
            zipfile.add(file[:name], file[:path])
          end
        end

        UI.success "Generate android debug file to #{desc_file}"

        Actions.lane_context[SharedValues::DSYM_ZIP_PATH] = desc_file
        ENV[SharedValues::DSYM_ZIP_PATH.to_s] = desc_file
      end

      def self.print_table(files)
        rows = files.each_with_object({}) do |file, obj|
          obj[file[:name]] = file[:path]
        end

        return if rows.empty?

        puts Terminal::Table.new(
          title: "Summary for proguard #{Fastlane::DebugFile::VERSION}".green,
          rows: rows
        )
      end

      def self.find_proguard_files(app_path, build_type)
        src_files = []
        MATCHES_FILES.each do |_, file|
          path, existed = find_file(app_path, file, build_type)
          UI.verbose("File path `#{path}` exist: #{existed}")
          next unless existed

          src_files << {
            name: file[:name],
            path: path
          }
        end

        src_files
      end

      def self.find_file(app_path, file, build_type)
        path = File.join(app_path, file[:path], build_type, file[:name])
        [path, File.exist?(path)]
      end
      private_class_method :find_file

      def self.zip_filename(build_type)
        "#{build_type}-#{Time.now.strftime('%Y%m%d%H%M')}.zip"
      end
      private_class_method :zip_filename

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Find and generate Android proguard file(s) to zip file'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :build_type,
                                       env_name: 'PROGUARD_BUILD_TYPE',
                                       description: 'The build type of app',
                                       default_value: RELEASE_TYPE,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :app_path,
                                       env_name: 'PROGUARD_PATH',
                                       description: 'The path of app project',
                                       default_value: APP_PATH,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :output_path,
                                       env_name: 'PROGUARD_OUTPUT_PATH',
                                       description: "The output path of zipped proguard file",
                                       default_value: File.join(APP_PATH, OUTPUT_PATH),
                                       optional: true,
                                       type: String)
        ]
      end

      def self.example_code
        [
          'android_(
            endpoint: "...",
            token: "...",
            plat_id: 123,
            file: "./app.{ipa,apk}"
          )'
        ]
      end

      def self.category
        :misc
      end

      def self.output
        [
          ['PROGUARDS', 'URL of the newly uploaded build']
        ]
      end

      def self.authors
        ['icyleaf']
      end

      def self.is_supported?(platform)
        platform == :android
      end
    end
  end
end
