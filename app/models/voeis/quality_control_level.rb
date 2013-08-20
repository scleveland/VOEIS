class Voeis::QualityControlLevel
  include DataMapper::Resource
  include Facet::DataMapper::Resource
  include Yogo::Versioned::DataMapper::Resource

  property :id,                         Serial
  property :quality_control_level_code, String, :required => true, :format => /[^\t|\n|\r]/
  property :definition,                 String, :required => true, :format => /[^\t|\n|\r]/
  property :explanation,                String, :required => true

  # repository(:default){
  property :his_id,            Integer, :required => false, :index => true
  # }

  yogo_versioned
  #timestamps :at

  #is_versioned :on => :updated_at
  has n,   :cv_types,  :model => "Voeis::CVType", :through => Resource

  def use_count
    # return use count
    count = 0
    count += Voeis::Variable.all(:quality_control=>self.quality_control_level_code).count
    count += Voeis::DataValue.all(:quality_control_level=>self.quality_control_level_code).count
    return count
  end
end