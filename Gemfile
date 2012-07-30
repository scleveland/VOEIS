source :rubygems

DM_VERSION = "1.1.0"

# Once the .freeze fix is integrated we can remove this again - IRJ
gem "dm-rest-adapter",                          :git => "git://github.com/yogo/dm-rest-adapter.git"
gem "yogo-framework"                            # The Yogo Framework
gem "yogo-project",                             :git => "git://github.com/yogo/yogo-project.git"

gem "dm-validations"                            # We're validating properties
gem "dm-is-versioned",                          :git => "git://github.com/yogo/dm-is-versioned.git", :branch => "voeis/patches", :ref =>"53acfa5faa34249b080acc398e0c865dd3d9ec1a"
gem "dm-types",        DM_VERSION               # To enable UUID types
gem "dm-is-list",      DM_VERSION               # RBAC
gem "dm-migrations",   DM_VERSION 
gem "dm-transactions", DM_VERSION
gem "dm-aggregates",   DM_VERSION
gem "dm-timestamps"

gem "geonames"  #geonames wrapper
gem "roo"
gem "nokogiri"

# We have been bitten many times by not including rails directly.
gem "rails"                                     # Rails application
# Only require of rails what we need, not the entire thing.

gem "activerecord", :require => "active_record"

gem "dm-rails",        DM_VERSION               # DataMapper integration with Rails

gem "jquery-rails"                              # jQuery integration with Rails
gem "compass", ">= 0.10.6"                      # Styling automation for views
gem "haml"                                      # HAML syntax for views
# Simplified Rails controllers
gem "inherited_resources",                      :git => "git://github.com/josevalim/inherited_resources.git",
                                                :ref => "5d988cfcfa632cc9c67fff4cb100594ea683482a"
gem "responders", "~> 0.6.2"

gem "rails_warden", "0.5.2"                              # Warden integration with Rails for authentication

gem "mime-types", :require => "mime/types"      # For uploading data files
gem "uuidtools"                                 # This is for memberships

gem 'i18n', "~> 0.4.0"

gem 'exception_notification',      :require => 'exception_notifier'

gem 'delayed_job',                 :git => 'git://github.com/yogo/delayed_job.git'
gem "cells", "~> 3.5.4"
gem 'apotomo', "~> 1.1"
gem 'aaronh-chronic',  :git =>"git://github.com/scleveland/chronic.git"

gem 'rql', ">= 0.0.1",        :git => "git://github.com/yogo/rql-ruby.git", :branch => 'voeis-rql'

# Rserve client -for 'R' interface
gem 'rserve-simpler',         :require => 'rserve/simpler'
gem "test-unit", "~> 1.2.1"  #this is apparently required so it is going here so rack works
platforms(:ruby_19) {
  gem "therubyracer", :require => "v8"
}
platforms(:jruby) { gem "therubyrhino" }

# Because in 1.9 fastercsv is default, but in 1.8...
platforms(:jruby) { gem "fastercsv" }

group(:development, :test) do
  gem "dm-visualizer"
  #gem "rails-footnotes", :git => "https://github.com/irjudson/rails-footnotes.git"
  # For rake tasks to work
  gem "rake",                      :require => nil
  # For deployment
  gem "capistrano",                :require => nil
  # RSpec 2.0 requirements
  gem "rspec"
  gem "rspec-core",                :require => "rspec/core"
  gem "rspec-expectations",        :require => "rspec/expectations"
  gem "rspec-mocks",               :require => "rspec/mocks"
  gem "rspec-rails"
  # YARD Documentation
  gem "yard",          "0.6.3",            :require => nil
  # gem "bluecloth",                 :require => nil
  gem "yardstick"
  # TODO: We need to find out how to remove this
  gem "test-unit", "~> 1.2.1",     :require => nil # This is annoying that is is required.
  # Debugger requirements
  platforms(:ruby_19) { gem "ruby-debug19", :require => nil }

end
