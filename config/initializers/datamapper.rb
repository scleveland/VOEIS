# Yogo Data Management Toolkit
# Copyright (c) 2010 Montana State University
#
# License -> see license.txt
#
# FILE: datamapper.rb
#

# Patch dm-rails to not try creating dm-rest repositories
# during `rake db:create`
require 'dm-rails/rest-storage.rb'

# Require custom extensions to datamapper.
# require 'datamapper/model'
require 'datamapper/search'
require 'datamapper/property/yogo_file'
require 'datamapper/property/yogo_image'
require 'datamapper/property/raw'

# Require Rql support for Datamapper
require 'rql/evaluator/datamapper'

# When saving models don't be terse
DataMapper::Model.raise_on_save_failure = true

# Read the configuration from the existing database.yml file
# config = Rails.configuration.database_configuration

# Load the project model and migrate it if needed.
Project
Setting
User
Role
Membership
Voeis::Site::Version
# Site
# Unit
# Variable
# FieldMethod
# VariableNameCV
# SampleMediumCV
# ValueTypeCV
# SpeciationCV
# DataTypeCV
# GeneralCategoryCV
# SampleTypeCV
# SampleMaterial
# LabMethod

# Make sure all of our models are required.
Dir[File.join(::Rails.root.to_s, 'app', 'models', '**', '*.rb')].each do |f|
  require f
end


DataMapper.finalize

DataMapper::Model.descendants.each do |model|
  begin
    require model
  rescue
  end
end

