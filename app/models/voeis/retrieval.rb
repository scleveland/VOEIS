class Voeis::Retrieval
  include DataMapper::Resource
  include Facet::DataMapper::Resource
  include Yogo::Versioned::DataMapper::Resource

  property :id,                  Serial
  property :retrieve_date,        DateTime, :required => true

  has 1, :deployment, :model => "Voeis::Deployment"

  yogo_versioned
end