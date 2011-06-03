class Voeis::SpatialOffsetType
  include DataMapper::Resource
  include Yogo::Versioned::DataMapper::Resource

  property :id,                 Serial
  property :type,               String, :required =>true, :length=> 512, :default=>"empty"
  
  timestamps :at
  yogo_versioned
 
  has n, :spatial_offsets, :model => "Voeis::SpatialOffset", :through => Resource

end