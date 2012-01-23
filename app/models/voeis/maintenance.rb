class Voeis::Maintenance
  include DataMapper::Resource
  include Facet::DataMapper::Resource
  include Yogo::Versioned::DataMapper::Resource

  property :id,                  Serial
  property :maintenance_date,     DateTime, :required => true
  property :type,                String, :required => true, :length => 512
  property :description,          Text
  
  belongs_to :instrument

  yogo_versioned
end