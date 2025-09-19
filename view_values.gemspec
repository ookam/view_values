# frozen_string_literal: true

require_relative 'lib/view_values/version'

Gem::Specification.new do |s|
  s.name        = 'view_values'
  s.version     = ViewValues::VERSION
  s.summary     = 'A tiny Ruby gem scaffold for view_values'
  s.description = 'Minimal scaffold with RSpec setup to start development.'
  s.license     = 'MIT'

  s.authors = ['Your Name']
  s.email   = ['you@example.com']

  s.required_ruby_version = '>= 3.2'

  s.homepage = 'https://example.com/view_values'

  # Package only files under this gem's directory (works in monorepos)
  s.files = Dir.glob(
    [
      'lib/**/*',
      'README.md',
      'LICENSE',
      File.basename(__FILE__)
    ]
  )

  s.bindir      = 'exe'
  s.executables = Dir.children('exe')
  s.require_paths = ['lib']

  s.add_dependency 'activesupport', '>= 6.1'

  # Recommended security setting for RubyGems
  s.metadata = (s.metadata || {}).merge('rubygems_mfa_required' => 'true')
end
