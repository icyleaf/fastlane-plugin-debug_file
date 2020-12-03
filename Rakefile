require 'bundler/gem_tasks'

$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))

require 'fastlane' # to import the Action super class
require 'fastlane/plugin/debug_file' # import the actual plugin

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new

require 'rubocop/rake_task'
RuboCop::RakeTask.new(:rubocop)

task(default: [:spec, :rubocop])

task :try do
  runner = DebugFile::Runner.new
  puts runner.latest_dsym(filter: :version)
end
