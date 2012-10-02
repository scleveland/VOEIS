class Voeis::CVType
  include DataMapper::Resource
  include Facet::DataMapper::Resource
  
  property :id,       Serial
  property :name,     String, :required => true, :length => 512, :index => true
  
  has n, :data_type_cvs, :model=>"Voeis::DataTypeCV", :through=>Resource
  has n, :general_category_cvs, :model=>"Voeis::GeneralCategoryCV", :through=>Resource
  has n, :quality_control_levels, :model=>"Voeis::QualityControlLevel", :through=>Resource
  has n, :sample_medium_cvs, :model=>"Voeis::SampleMediumCV", :through=>Resource
  has n, :sample_type_cvs, :model=>"Voeis::SampleTypeCV", :through=>Resource
  has n, :speciation_cvs, :model=>"Voeis::SpeciationCV", :through=>Resource
  has n, :value_type_cvs, :model=>"Voeis::ValueTypeCV", :through=>Resource
  has n, :variable_name_cvs, :model=>"Voeis::VariableNameCV", :through=>Resource
  has n, :vertical_datum_cvs, :model=>"Voeis::VerticalDatumCV", :through=>Resource
  has n, :spatial_references, :model=>"Voeis::SpatialReference", :through=>Resource
  has n, :sensor_type_cvs, :model=>"Voeis::SensorTypeCV", :through=>Resource
  has n, :logger_type_cvs, :model=>"Voeis::LoggerTypeCV", :through=>Resource
  has n, :units, :model=>"Voeis::Unit", :through=>Resource
end
