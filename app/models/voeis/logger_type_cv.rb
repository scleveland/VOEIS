class Voeis::LoggerTypeCV
  include DataMapper::Resource
  include Yogo::Versioned::DataMapper::Resource

  property :id,         Serial
  property :term,       String, :required => true, :index => true, :format => /[^\t|\n|\r]/
  property :description, Text
  
  yogo_versioned

end