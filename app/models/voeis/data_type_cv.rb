# DataTypeCV
#
# The DataType CV table contains the controlled vocabulary for the DataType field in
# the Variable model
#
class Voeis::DataTypeCV
  include DataMapper::Resource
  include Facet::DataMapper::Resource
  include Yogo::Versioned::DataMapper::Resource

  property :id,         Serial
  property :term,       String, :required => true, :index => true, :format => /[^\t|\n|\r]/
  property :definition, Text
  
  yogo_versioned

  has n,   :cv_types,  :model => "Voeis::CVType", :through => Resource
  
  def self.load_from_his
    his_data_types = His::DataTypeCV.all

    his_data_types.each do |his_dt|
        self.first_or_create(
                    :term => his_dt.term,
                    :definition=> his_dt.definition)

    end
  end

  def store_to_his(u_id)
    data_type_to_store = self.first(:id => u_id)
    if data_type_to_store.is_regular == true
      reg = 1
    else
      reg =0
    end
    new_his_data_type = His::DataTypeCV.new(:term => data_type_to_store.term,
                                        :definition => data_type_to_store.definition)
    new_his_data_type.save
    puts new_his_data_type.errors.inspect
    data_type_to_store.his_id = new_his_data_type.id
    data_type_to_store.save
    new_his_data_type
  end
  
  def use_count
    # return use count
    count = 0
    count += Voeis::Variable.all(:data_type=>self.term).count
    return count
  end
end
