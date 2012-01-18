

class Voeis::DataSet
  include DataMapper::Resource
  include Facet::DataMapper::Resource
  include Yogo::Versioned::DataMapper::Resource

  property :id,          Serial
  property :name,        String,  :required => true, :unique => true, :length => 512
  property :type,        String, :required => true, :default => "default"
  property :description, Text,    :required => false
  
  yogo_versioned

  validates_uniqueness_of   :name
  has n, :data_values,         :model => "Voeis::DataValue",        :through =>Resource
  #has permissions
  #has n, :users,  :through =>Voeis::DataSetUser, :parent_key => [ :id ], :child_key  => [ :data_set_id ]
  
  def variables
    #get all unique variable ids and the fetch all variables and return as an array
    sql = "SELECT DISTINCT variable_id FROM voeis_data_values WHERE id IN "
    sql  = sql + self.data_values.map{|v| v.id}.to_s.gsub('[', '(').gsub(']',')')
    results = repository.adapter.select(sql)
    results.map{|v| Voeis::Variable.get(v)}
  end
  
  def count
    self.data_values.count
  end
  
  def get_dv_by_var_id(var_id)
    self.data_values.all(:variable_id => var_id)
  end
  
  def add_data_values(data_value_ids)
    data_sql = Array.new
    data_sql = data_value_ids.map{|data_value_id| "(#{self.id},#{data_value_id})"}
    sql = "INSERT INTO \"voeis_data_set_data_values\" (\"data_set_id\",\"data_value_id\") VALUES "
    puts sql << data_sql.join(',')
    repository.adapter.execute(sql)
    self.data_values
  end
  
  def add_user(user)
    User.first_or_create(user.attributes)
    
  end
end
