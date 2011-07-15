
class Voeis::Lab
  include DataMapper::Resource
  include Facet::DataMapper::Resource
  include Yogo::Versioned::DataMapper::Resource
  
  property :id,                     Serial
  property :lab_name,               Text, :required => true, :default => 'Unknown', :format => /[^\t|\n|\r]/
  property :lab_organization,       Text, :required => true, :default => 'Unknown', :format => /[^\t|\n|\r]/
  
  
  has n, :variables, :model => "Voeis::Variable", :through => Resource
  yogo_versioned
  
  def self.load_from_his

  end

  def store_to_his(u_id)

  end
  
end
