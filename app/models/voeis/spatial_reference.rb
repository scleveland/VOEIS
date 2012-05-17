class Voeis::SpatialReference
  include DataMapper::Resource
  include Facet::DataMapper::Resource
  include Yogo::Versioned::DataMapper::Resource

  property :id,         Serial
  property :srs_id,      Integer
  property :srs_name,       String, :required => true, :index => true, :length => 512
  property :is_geographic, Boolean
  property :notes, Text

  yogo_versioned

  has n, :sites,             :model => "Voeis::Site",         :through => Resource, :required=>false

end