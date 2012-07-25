#This is the Application Wide Role based access permissions
#  Role is project specific permissions
require 'dm-core'
require 'dm-types/yaml'
class SystemRole
  include DataMapper::Resource
  include Facet::DataMapper::Resource

  alias :update_attributes :update
  property :id, Serial
  property :name, String, :required => true
  property :description, String, :length => 250
  property :actions, Yaml, :default => [].to_yaml

  has n, :users

  is :list

  def self.permission_sources
    [Project, Role, User, SystemRole, Membership]
  end

  def self.available_permissions
    @_availaible_permissions ||= permission_sources.map {|ps| ps.to_permissions}.flatten
  end

  def self.available_permissions_by_source
    source_hash = Hash.new
    permission_sources.each { |ps| source_hash[ps.name] = ps.to_permissions }
    source_hash
  end

  def has_permission?(permission)
    actions.include?(permission)
  end

end