class Voeis::Campaign
  include DataMapper::Resource
  include Facet::DataMapper::Resource

  property :id,                  Serial
  property :date_begun,          DateTime
  property :date_ended,          DateTime
  property :description,         Text

  has n, :users, :through => Resource
  has n, :projects, :through => Resource
  has n, :visits, :through => Resource

  timestamps :at
  is_versioned :on => :updated_at
end