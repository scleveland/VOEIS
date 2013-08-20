class Voeis::CVType
  include DataMapper::Resource
  include Facet::DataMapper::Resource
  include Yogo::Versioned::DataMapper::Resource
  
  property :id,       Serial
  property :name,     String, :required => true, :length => 512, :index => true

  yogo_versioned
  
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
  
  def use_count
    # return use count
    count = 0
    count += self.data_type_cvs.count
    count += self.general_category_cvs.count
    count += self.quality_control_levels.count
    count += self.sample_medium_cvs.count
    count += self.sample_type_cvs.count
    count += self.speciation_cvs.count
    count += self.value_type_cvs.count
    count += self.variable_name_cvs.count
    count += self.vertical_datum_cvs.count
    count += self.spatial_references.count
    count += self.sensor_type_cvs.count
    count += self.logger_type_cvs.count
    count += self.units.count
    return count
  end

end
