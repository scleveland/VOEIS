class Voeis::Retrieval
  include DataMapper::Resource
  include Facet::DataMapper::Resource
  include Yogo::Versioned::DataMapper::Resource

  property :id,                  Serial
  property :retrieve_date,        DateTime, :required => true

  belongs_to :deployment, :model => "Voeis::Deployment", :required => false
 
  yogo_versioned
end