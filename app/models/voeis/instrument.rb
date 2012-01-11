class Voeis::Instrument
  include DataMapper::Resource
  include Facet::DataMapper::Resource
  include Yogo::Versioned::DataMapper::Resource

  property :id,                  Serial
  property :name,                String, :required => true, :length => 512
  property :description,         Text
  property :serial_number,       String, :length=> 512
  property :sensor_type,                String, :required => true, :length => 512
  property :calibration_constant, Float
  property :purchase_date,        DateTime
  property :manufacturer,         String
  property :link,                 String, :length => 512
  property :model_name,         String, :length => 512

  #has n, :field_methods, :through => Resource
  #has n, :lab_methods, :through => Resource
  #has 1, :vendor
  has n, :variables, :model => "Voeis::Variable",    :through => Resource
  has n, :deployments
  has n, :maintenances

  yogo_versioned
end