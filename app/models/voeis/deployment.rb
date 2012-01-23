class Voeis::Deployment
  include DataMapper::Resource
  include Facet::DataMapper::Resource
  include Yogo::Versioned::DataMapper::Resource

  property :id,                  Serial
  property :deploy_date,        DateTime, :required => true

  belongs_to :instrument
  belongs_to :site
  has 1, :retrieval, :required => false, :model => "Voeis::Retrieval"

  yogo_versioned
end