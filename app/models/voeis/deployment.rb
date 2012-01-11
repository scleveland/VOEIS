class Voeis::Deployment
  include DataMapper::Resource
  include Facet::DataMapper::Resource
  include Yogo::Versioned::DataMapper::Resource

  property :id,                  Serial
  property :deploy_date,        DateTime, :required => true

  has 1, :instrument
  has 1, :site
  has 1, :retieval, :required => false, :model => "Voeis::Retrieval"

  yogo_versioned
end