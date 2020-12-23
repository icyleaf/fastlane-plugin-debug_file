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
      return [fetch_project_info(archive_path)] if project_archive_path? && !options[:scheme]

      search_dsym(archive_path, options[:scheme])
    end

    private

    def search_dsym(path, scheme = nil)
      project_path = File.join(path, '**', '*.xcarchive')
      obj = []
      Dir.glob(project_path) do |path|
        next unless item = fetch_project_info(path, scheme)

        yield item if block_given?
        obj << item
      end

      obj
    end

    def fetch_project_info(path, scheme = nil)
      info = Fastlane::Helper::DebugFileHelper.xcarchive_metadata(File.join(path, 'Info.plist'))
      name = Fastlane::Helper::DebugFileHelper.fetch_key(info, 'Name')
      return unless scheme.to_s.empty? || scheme == name

      release_version = Fastlane::Helper::DebugFileHelper.fetch_key(info, 'ApplicationProperties', 'CFBundleShortVersionString')
      build = Fastlane::Helper::DebugFileHelper.fetch_key(info, 'ApplicationProperties', 'CFBundleVersion')
      dsym_path = File.join(path, 'dSYMs', "#{name}.app.dSYM")
      dsym_binray_path = Dir.glob(File.join(dsym_path, '**', '*', name)).first
      created_at = Fastlane::Helper::DebugFileHelper.fetch_key(info, 'CreationDate')

      machos = []
      Fastlane::Helper::DebugFileHelper.macho_metadata(dsym_binray_path).each do |macho|
        machos << {
          arch: macho.cpusubtype,
          uuid: macho[:LC_UUID][0].uuid_string
        }
      end

      {
        root_path: File.basename(File.dirname(path)),
        dsym_path: dsym_path,
        machos: machos,
        info: info,
        name: name,
        release_version: release_version,
        build: build,
        created_at: created_at,
      }
    end

    def project_archive_path?
      File.file?(File.join(archive_path, 'Info.plist')) &&
        Dir.exist?(File.join(archive_path, 'dSYMs'))
    end

    def archive_path
      @archive_path ||= File.expand_path(options.fetch(:archive_path, ARCHIVE_PATH))
    end
  end
end
