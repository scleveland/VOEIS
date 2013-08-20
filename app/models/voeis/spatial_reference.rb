class Voeis::SpatialReference
  include DataMapper::Resource
  include Facet::DataMapper::Resource
  include Yogo::Versioned::DataMapper::Resource

  property :id,         Serial
  property :srs_id,      Integer
  property :srs_name,       String, :required => true, :index => true, :length => 512
  property :is_geographic, Boolean
  property :notes, Text

  yogo_versioned

  has n,  :sites,     :model => "Voeis::Site",         :through => Resource, :required=>false
  has n,  :cv_types,  :model => "Voeis::CVType", :through => Resource

  def use_count
    # return use count
    count = 0
    count += Voeis::Site.all(:lat_long_datum_id=>self.id).count
    count += Voeis::Site.all(:local_projection_id=>self.id).count
    return count
  end
end