# frozen_string_literal: true

require 'fastlane/action'
require_relative '../helper/debug_file_helper'

module Fastlane
  module Actions
    module SharedValues
      DF_PROGUARD_ZIP_PATH = :DF_PROGUARD_ZIP_PATH
    end

    class ProguardAction < Action
      MATCHES_FILES = {
        mapping: {
          name: 'mapping.txt',
          path: 'build/outputs/mapping'
        },
        manifest: {
          name: 'AndroidManifest.xml',
          path: 'build/intermediates/manifests/full'
        },
        symbol: {
          name: 'R.txt',
          path: 'build/intermediates/symbols'
        }
      }

      APP_PATH = 'app'
      RELEASE_TYPE = 'release'
      OUTPUT_PATH = '.'

      def self.run(params)
        app_path = params[:app_path]
        build_type = params[:build_type]
        flavor = params[:flavor]
        overwrite = params[:overwrite]
        extra_files = params[:extra_files]
        output_path = params[:output_path]
        output_file = File.join(output_path, zip_filename(build_type, flavor))

        determine_output_file(output_file, overwrite)

        src_files = find_proguard_files(app_path, build_type, flavor, extra_files)
        UI.user_error! 'No found any proguard file' if src_files.empty?

        UI.success "Found #{src_files.size} debug information files"
        Helper::DebugFileHelper.compress(src_files, output_file)

        UI.success "Compressed proguard files: #{output_file}"
        Actions.lane_context[SharedValues::DF_PROGUARD_ZIP_PATH] = output_file
        ENV[SharedValues::DF_PROGUARD_ZIP_PATH.to_s] = output_file
      end

      def self.find_proguard_files(app_path, build_type, flavor, extra_files)
        src_files = []
        MATCHES_FILES.each do |_, file|
          path, existed = find_file(app_path, file, build_type, flavor)
          UI.verbose("File path `#{path}` exist: #{existed}")
          next unless existed

          src_files << {
            name: file[:name],
            path: path
          }
        end

        extra_files.each do |file|
          existed = File.exist?(file)
          UI.verbose("File path `#{file}` exist: #{existed}")
          next unless existed

          src_files << {
            name: File.basename(file),
            path: file
          }
        end

        src_files.uniq
      end

      def self.find_file(app_path, file, build_type, flavor)
        flavor ||= ''
        path = File.join(app_path, file[:path], flavor, build_type, file[:name])
        [path, File.exist?(path)]
      end
      private_class_method :find_file

      def self.zip_filename(build_type, flavor = nil)
        flavor = flavor.to_s.empty? ? '' : "#{flavor}-"
        "#{flavor}#{build_type}-proguard.zip"
      end
      private_class_method :zip_filename

      def self.determine_output_file(output_file, overwrite)
        if File.exist?(output_file)
          if overwrite
            File.rm output_file
          else
            UI.user_error! "Compressed proguard file was existed: #{output_file}"
          end
        end
      end
      private_class_method :determine_output_file

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Find and generate Android proguard file(s) to zip file'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :app_path,
                                       env_name: 'DF_PROGUARD_PATH',
                                       description: 'The path of app project',
                                       default_value: APP_PATH,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :build_type,
                                       env_name: 'DF_PROGUARD_BUILD_TYPE',
                                       description: 'The build type of app',
                                       default_value: RELEASE_TYPE,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :flavor,
                                       env_name: 'DF_PROGUARD_FLAVOR',
                                       description: 'The product flavor of app',
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :extra_files,
                                       env_name: 'DF_PROGUARD_EXTRA_FILES',
                                       description: 'The extra files of app project',
                                       optional: true,
                                       default_value: [],
                                       type: Array),
          FastlaneCore::ConfigItem.new(key: :output_path,
                                       env_name: 'DF_PROGUARD_OUTPUT_PATH',
                                       description: "The output path of compressed proguard file",
                                       default_value: OUTPUT_PATH,
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :overwrite,
                                       env_name: 'DF_PROGUARD_OVERWRITE',
                                       description: "Overwrite output compressed file if it existed",
                                       default_value: false,
                                       type: Boolean)
        ]
      end

      def self.example_code
        [
          'proguard',
          'proguard(
            build_type: "release",
            flavor: "full"
          )'
          'proguard(
            extra_files: [
              "app/src/main/AndroidManifest.xml"
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
          ['DF_PROGUARD_ZIP_PATH', 'the path of compressed proguard file']
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
