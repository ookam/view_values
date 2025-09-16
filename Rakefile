# frozen_string_literal: true

require 'rake'
require 'rspec/core/rake_task'

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new(:rubocop)
rescue LoadError
  # rubocop not installed yet
end

RSpec::Core::RakeTask.new(:spec)

task default: :spec

begin
  require 'bundler/gem_tasks'
rescue LoadError
  # bundler not present
end
