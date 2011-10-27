require 'rubygems'
require 'bundler'
Bundler.setup
Bundler::GemHelper.install_tasks

require 'rake'
require 'rdoc/task'
require 'rspec/core/rake_task'

desc 'Default: run unit tests.'
task :default => [:test]

RSpec::Core::RakeTask.new :test

desc 'Generate documentation for the famili plugin.'
RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = 'Famili'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end