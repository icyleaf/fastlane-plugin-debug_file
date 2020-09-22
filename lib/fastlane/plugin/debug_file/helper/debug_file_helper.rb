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
            if File.file?(file)
              zipfile.add File.basename(file), file
            else
              root_path = "#{File.dirname(file)}/"
              Dir[File.join(file, '**', '*')].each do |path|
                zip_path = path.sub(root_path, '')
                zipfile.add(zip_path, path)
              end
            end
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

      def self.macho_metadata(file)
        require 'macho'

        macho_type = MachO.open(file)
        case macho_type
        when ::MachO::MachOFile
          [macho_type]
        else
          size = macho_type.fat_archs.each_with_object([]) do |arch, obj|
            obj << arch.size
          end

          machos = []
          macho_type.machos.each do |file|
            machos << file
          end
          machos
        end
      end

      def self.store_shard_value(key, value)
        Actions.lane_context[key] = value
        ENV[key.to_s] = value
      end

      def self.xcarchive_metadata(path)
        file = File.directory?(path) ? File.join(path, 'Info.plist') : path
        UI.user_error! "Can not read Info.plist in #{file}" unless File.file?(file)

        require 'plist'
        Plist.parse_xml(file)
      end

      def self.fetch_key(plist, *keys)
        UI.crash! 'Missing keys' if keys.empty?

        if keys.size == 1
          plist[keys[0]]
        else
          plist.dig(*keys)
        end
      end
    end
  end
end
