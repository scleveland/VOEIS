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
    self.map{|k| k.to_hash}.to_json
  end
  def sql_to_xml
    self.map{|k| k.to_hash}.to_xml
  end
  def sql_to_csv
    header = self[0].to_hash.keys.map{|k| k}.join(',') + "\n"
    header << self.map{|k| k.to_a.to_csv}.join("\n")
  end
end

class String
  def valid_float?
    # The double negation turns this into an actual boolean true - if you're 
    # okay with "truthy" values (like 0.0), you can remove it.
    !!Float(self) rescue false
  end
end

module DataMapper
  def self.raw_select(dm_query)
    statement, bind_vars = repository.adapter.send(:select_statement, dm_query.query)
    sql = repository.adapter.send(:open_connection).create_command(statement).send(:escape_sql, bind_vars)
    repository.adapter.select(sql)
  end
end
# Initialize the rails application
Yogo::Application.initialize!


class Time
  def round(seconds = 60)
    Time.at((self.to_f / seconds).round * seconds)
  end
end