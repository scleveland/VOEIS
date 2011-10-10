require 'dm-core'
require 'dm-is-versioned'

# for Dirty Field list
UPDATED_FIELDS = 'Updated Fields: '
# Fields ending _id that are NOT references
ID_EXCEPTIONS = ['his_id']

module Yogo
  module Versioned
    # for Dirty Field list
    @@updated_fields = 'Updated Fields: '
    # Fields ending _id that are NOT references
    @@id_exceptions = ['his_id']
    
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
        dirty_props = self.dirty_attributes.keys.map{|k| k.name.to_s }-['id','updated_at','provenance_comment']
        dirty_props = dirty_props.map{|p| 
          #p = p[0..-4] if (p[-3..-1]=='_id' && !@@id_exceptions.include?(p))
          (p[-3..-1]=='_id' && !::ID_EXCEPTIONS.include?(p)) ? p[0..-4] : p
        }
        self.updated_at = Time.now
        self.updated_by = User.current.id
        self.updated_comment = "Edited at %s by %s %s [%s] - " % 
          [self.updated_at.strftime('%Y-%m-%d %H:%M:%S'), User.current.first_name, User.current.last_name ,User.current.login]
        #self.updated_comment += @@updated_fields+(dirty_props.join(', '))
        self.updated_comment += ::UPDATED_FIELDS+(dirty_props.join(', '))
        ##self.updated_comment = "Edited at #{Time.now.strftime('%Y-%m-%d %H:%M:%S')} by #{User.current.first_name} #{User.current.last_name} [#{User.current.login}]"
      end

      # Register with dm-is-versioned
      is_versioned :on => [:updated_at]
    end # yogo_versioned
  
    module DataMapper
      module Resource
        def self.included(base)
          base.class_eval do
            extend Yogo::Versioned
            #include Facet::ResourceSecureMethods
          end
        end

        # Dirty Field list
        def get_dirty(updated_comment=self.updated_comment)
          #if !(dirty_props = /#{Regexp.quote(@@updated_fields)}(.*)$/.match(updated_comment)).blank?
          #  return dirty_props[1].split(/, ?/)
          if !(dirty_props = /#{Regexp.quote(::UPDATED_FIELDS)}(.*)$/.match(updated_comment)).blank?
            return dirty_props[1].split(/, ?/)
          else
            return []
          end
        end
        
      end # Resource
    end # DataMapper
  end # Versioned
end # Yogo
