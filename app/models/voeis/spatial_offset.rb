class Voeis::SpatialOffset
  include DataMapper::Resource
  include Facet::DataMapper::Resource
  include Yogo::Versioned::DataMapper::Resource

  property :id,                 Serial
  property :type,               String, :required =>true, :length=> 512, :default=>"empty"
  property :value,              String,   :required => true
  property :units_id,           Integer,   :required => false
  
  #timestamps :at
  yogo_versioned
 
  has n, :variables, :model => "Voeis::Variable", :through => Resource
  #has 1, :unit,      :model => "Voeis::Unit",     :through => Resource

end