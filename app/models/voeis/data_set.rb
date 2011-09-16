

class Voeis::DataSet
  include DataMapper::Resource
  include Facet::DataMapper::Resource
  include Yogo::Versioned::DataMapper::Resource

  property :id,          Serial
  property :name,        String,  :required => true, :unique => true, :length => 512
  property :description, Text,    :required => false
  
  yogo_versioned

  validates_uniqueness_of   :name
  has n, :data_values,         :model => "Voeis::DataValue",        :through =>Resource
  #has permissions
  #has users
  
end
