# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "log_service/version"

Gem::Specification.new do |s|
  s.name        = "log_service"
  s.version     = LogService::VERSION
  s.authors     = ["Justin Rhinesmith"]
  s.email       = "jrhinesmith@questlearning.org"
  s.homepage    = "https://github.com/opportunity-education/log_service_gem"
  s.summary     = "OE Log Service API Client"
  s.description = "Send events from your Ruby applications."
  s.license     = "MIT"

  s.add_dependency "multi_json", "~> 1.3"
  s.add_dependency "addressable", "~> 2.3.5"

  # guard
  unless RUBY_VERSION.start_with? '1.8'
    s.add_development_dependency 'guard'
    s.add_development_dependency 'guard-rspec'

    # guard cross-platform listener trick
    s.add_development_dependency 'rb-inotify'
    s.add_development_dependency 'rb-fsevent'
    s.add_development_dependency 'rb-fchange'

    # guard notifications
    s.add_development_dependency 'ruby_gntp'

    # fix guard prompt
    s.add_development_dependency 'rb-readline' # or compile ruby w/ readline
  end

  # debuggers
  if /\Aruby/ === RUBY_DESCRIPTION
    s.add_development_dependency 'ruby-debug' if RUBY_VERSION.start_with? '1.8'
    s.add_development_dependency 'debugger'   if RUBY_VERSION.start_with? '1.9'
  end

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
