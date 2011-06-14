class Voeis::SiteDataCatalog
  include DataMapper::Resource
  include Facet::DataMapper::Resource
  
  property :site_id,             Integer,  :required => true, :key => true
  property :variable_id,         Integer,  :required => true, :key => true
  property :record_number,       Integer, :required => true, :default => 0
  property :starting_timestamp,  DateTime, :required => false
  property :ending_timestamp,    DateTime, :required => false



  
end