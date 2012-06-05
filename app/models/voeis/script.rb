class Voeis::Script
  include DataMapper::Resource
  include Facet::DataMapper::Resource
  include Yogo::Versioned::DataMapper::Resource
  
  property :id,                     Serial
  property :name,                   String,   :required => true, :length => 512
  property :script_type,            Integer,  :required => false, :default=>0
  property :script_class,           String,   :required => false, :default => ''
  property :script_body,            Text,     :required => false, :default => ''
  property :description,            Text,    :required => false, :default => ''
  
  yogo_versioned
  
  
end
