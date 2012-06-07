class Voeis::SensorTypeCV
  include DataMapper::Resource
  include Facet::DataMapper::Resource
  include Yogo::Versioned::DataMapper::Resource

  property :id,         Serial
  property :term,       String, :required => true, :index => true, :format => /[^\t|\n|\r]/
  property :description, Text
  
  yogo_versioned
  has n,   :cv_types,  :model => "Voeis::CVType", :through => Resource
end