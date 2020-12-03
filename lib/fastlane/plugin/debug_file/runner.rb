module DebugFile
  class Runner
    ARCHIVE_PATH = File.expand_path('~/Library/Developer/Xcode/Archives')

    attr_accessor :options

    def initialize(options = {})
      @options = options
    end

    def latest_dsym(filter: :date)
      dsyms = list_dsym
      case filter
      when :version
        dsyms.max_by {|v| Gem::Version.new(v[:release_version])}
      else
        dsyms.max_by {|v| v[:created_at]}
      end
    end

    def list_dsym
      archive_path = File.expand_path(options.fetch(:archive_path, ARCHIVE_PATH))
      search_dsym(archive_path, options[:scheme])
    end

    private

    def search_dsym(path, scheme = nil)
      info_path = File.join(path, '**', '*.xcarchive', 'Info.plist')
      matched_paths = []

      obj = []
      Dir.glob(info_path) do |path|
        info = Fastlane::Helper::DebugFileHelper.xcarchive_metadata(path)
        name = Fastlane::Helper::DebugFileHelper.fetch_key(info, 'Name')
        next unless scheme.to_s.empty? || scheme == name

        release_version = Fastlane::Helper::DebugFileHelper.fetch_key(info, 'ApplicationProperties', 'CFBundleShortVersionString')
        build = Fastlane::Helper::DebugFileHelper.fetch_key(info, 'ApplicationProperties', 'CFBundleVersion')
        dsym_path = Dir.glob(File.join(File.dirname(path), 'dSYMs', "#{name}.app.dSYM", '**', '*', name)).first
        created_at = Fastlane::Helper::DebugFileHelper.fetch_key(info, 'CreationDate')

        machos = []
        Fastlane::Helper::DebugFileHelper.macho_metadata(dsym_path).each do |macho|
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
  end
end
