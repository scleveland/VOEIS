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
end