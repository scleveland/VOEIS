# Origin Class 
# This is used to describe a data-value
#  
# @example  Creating a Origin
#   Origin.create()
#
# @param [Integer] :id, the unique integer id assigned to this object by VOEIS       
#         
# @author Sean Cleveland
#
class Voeis::Origin
  include DataMapper::Resource
  include Facet::DataMapper::Resource
  include Yogo::Versioned::DataMapper::Resource

  property :id,                Serial
  

  yogo_versioned  #extend the model and add the version properties

  #has n, :data_values,        :model => "Voeis::DataValue"
  #has 1, :variable_name,      :model => "Voeis::VariableNameCV"
  #has 1, :origin_type,        :model => "Voeis::OriginType"
  #has 1, :source,             :model => "Voeis::Source"
  #has 1, :unit,               :model => "Voeis::Unit"
  #has 1, :activity,           :model => "Voeis::Activity"
  

end