class Voeis::Source
  include DataMapper::Resource
  include Facet::DataMapper::Resource
  include Yogo::Versioned::DataMapper::Resource


  property :id,                 Serial
  property :organization,       String,  :required => true                      , :format => /[^\t|\n|\r]/, :length => 512
  property :source_description, Text,  :required => true
  property :source_link,        String, :length => 512
  property :contact_name,       String,  :required => true, :default => "Unknown", :format => /[^\t|\n|\r]/
  property :phone,              String,  :required => true, :default => "Unknown", :format => /[^\t|\n|\r]/
  property :email,              String,  :required => true, :default => "Unknown", :format => :email_address, :length => 512
  property :address,            String,  :required => true, :default => "Unknown", :format => /[^\t|\n|\r]/, :length => 512
  property :city,               String,  :required => true, :default => "Unknown", :format => /[^\t|\n|\r]/
  property :state,              String,  :required => true, :default => "Unknown", :format => /[^\t|\n|\r]/
  property :zip_code,           String,  :required => true, :default => "Unknown", :format => /[^\t|\n|\r]/
  property :citation,           String, :default => "Unknown", :length => 512
  property :metadata_id,        Integer, :required => true, :default => 0
  property :his_id,             Integer, :required=>false
  #timestamps :at
  
  yogo_versioned
  
  has n, :samples,             :model => "Voeis::Sample",         :through => Resource
  has n, :data_values,         :model => "Voeis::DataValue",      :through => Resource
  has n, :sensor_values,       :model => "Voeis::SensorValue",    :through => Resource
  has n, :data_streams,        :model => "Voeis::DataStream",     :through => Resource
  
  def store_to_his
     if self.his_id.nil?
       new_his_src = His::Source.new(:organization => self.organization,      
                                     :source_description => self.source_description,
                                     :source_link=>self.source_link,       
                                     :contact_name=>self.contact_name,      
                                     :phone=>self.phone,             
                                     :email=>self.email,             
                                     :address=>self.address,           
                                     :city=>self.city,              
                                     :state=>self.state,             
                                     :zip_code=>self.zip_code,          
                                     :citation=>self.citation,          
                                     :metadata_id=>self.metadata_id)     
       new_his_src.valid?                      
       puts new_his_src.errors.inspect
       new_his_src.save
       self.his_id = new_his_src.id
       self.save
       new_his_src
     else
       His::Source.get(self.his_id)
     end
   end
end