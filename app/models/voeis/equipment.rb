class Voeis::Equipment
  include DataMapper::Resource
  include Facet::DataMapper::Resource
  include Yogo::Versioned::DataMapper::Resource

  property :id,                  Serial
  property :name,                String, :length => 512
  property :description,         Text
  property :serial_number,       String, :required => false, :length=> 512


  has n, :field_methods, :through => Resource
  has n, :lab_methods, :through => Resource
  #has 1, :vendor

  yogo_versioned
end