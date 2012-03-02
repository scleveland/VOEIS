# Yogo Data Management Toolkit
# Copyright (c) 2010 Montana State University
#
# License -> see license.txt
#
# FILE: environment.rb
#
#
# Be sure to restart your server when you modify this file

# Load the rails application
require File.expand_path('../application', __FILE__)

require 'rack/rql'
Yogo::Application.configure do
  config.middleware.insert_before(ActionDispatch::Head, Rack::RqlQuery)
end
#extend the Struct class
class Struct
   def to_hash
     Hash[*members.zip(values).flatten]
   end
 end
#extend Array so that raw sql results can be converted to json easily
#assumes this is an array of Structs or Objects that have the to_hash method
class Array
  def sql_to_json
    self.map{|k| k.to_hash}.as_json
  end
end
# Initialize the rails application
Yogo::Application.initialize!


