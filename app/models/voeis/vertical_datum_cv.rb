class Voeis::VerticalDatumCV
  include DataMapper::Resource
  include Facet::DataMapper::Resource
  include Yogo::Versioned::DataMapper::Resource

  property :id,         Serial
  property :term,       String, :required => true, :index => true, :length => 512
  property :definition, Text

  yogo_versioned

  has n,  :sites,     :model => "Voeis::Site",         :through => Resource, :required=>false
  has n,  :cv_types,  :model => "Voeis::CVType", :through => Resource

  def use_count
    # return use count
    return Voeis::Site.all(:vertical_datum_id=>self.id).count
  end
end