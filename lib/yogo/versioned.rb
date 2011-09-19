require 'dm-core'
require 'dm-is-versioned'

module Yogo
  module Versioned
    def yogo_versioned
      property :provenance_comment,     ::DataMapper::Property::Text, :required => false
      # User update comment -- avoid hook updates
      # Add properties required for versioning
      property :updated_at,          ::DataMapper::Property::DateTime#, :key=>true, :default=>DateTime.now
      property :updated_by,          ::DataMapper::Property::Integer
      property :updated_comment,     ::DataMapper::Property::Text
      property :created_at,          ::DataMapper::Property::DateTime, :required => false
      property :deleted_at,          ::DataMapper::Property::ParanoidDateTime
      timestamps :created_at

      # Register before save hooks
      before(:save) do
        self.updated_at = Time.now
        self.updated_by = User.current.id
        self.updated_comment = "Edited at #{self.updated_at.strftime('%Y-%m-%d %H:%M:%S')} by #{User.current.first_name} #{User.current.last_name} [#{User.current.login}]"
        ##self.updated_comment = "Edited at #{Time.now.strftime('%Y-%m-%d %H:%M:%S')} by #{User.current.first_name} #{User.current.last_name} [#{User.current.login}]"
      end

      # Register with dm-is-versioned
      is_versioned :on => [:updated_at]
    end

    module DataMapper
      module Resource
        def self.included(base)
          base.class_eval do
            extend Yogo::Versioned
            #include Facet::ResourceSecureMethods
          end
        end
      end # Resource
    end # DataMapper
  end # Versioned
end # Yogo
