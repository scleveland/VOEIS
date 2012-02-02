

class Voeis::DataSet
  include DataMapper::Resource
  include Facet::DataMapper::Resource
  include Yogo::Versioned::DataMapper::Resource

  property :id,          Serial
  property :name,        String,  :required => true, :unique => true, :length => 512
  property :type,        String, :required => true, :default => "default"
  property :description, Text,    :required => false
  property :data_value_count, Integer, :required => false
  
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
  
  def update_count
    sql = "UPDATE voeis_data_sets SET data_value_count=#{self.data_values.count} WHERE id=#{self.id}"
    repository.adapter.execute(sql)
  end
  
  def count
    self.data_values_count
  end
  
  def get_dv_by_var_id(var_id)
    self.data_values.all(:variable_id => var_id)
  end
  
  # This will ignore data_values
  def add_data_values(data_value_ids)
    int_data_value_ids = data_value_ids.map{|k| k.to_i}
    current_ids = self.data_values.map{|k| k.id}
    data_sql = Array.new
    unless (int_data_value_ids-current_ids).empty?
      data_sql = (int_data_value_ids-current_ids).map{|data_value_id| "(#{self.id},#{data_value_id})"}
      sql=  "INSERT INTO \"voeis_data_set_data_values\" (\"data_set_id\",\"data_value_id\") VALUES "
      puts sql << data_sql.join(',')
      repository.adapter.execute(sql)
      self.update_count
    end
    self.data_values
  end
  
  
  def remove_data_values(data_value_ids)
    int_data_value_ids = data_value_ids.map{|k| k.to_i}
    data_sql = Array.new
    sql=""
    data_sql = (int_data_value_ids).map{|data_value_id| "(#{self.id},#{data_value_id})"}
    sql=  "DELETE FROM \"voeis_data_set_data_values\" WHERE (\"data_set_id\",\"data_value_id\") IN ("
    puts sql << data_sql.join(',')
    sql = sql +")"
    repository.adapter.execute(sql)
    self.update_count
    self.data_values
  end
  
  def add_user(user)
    User.first_or_create(user.attributes)
    
  end
  
  def protovis_csv
    csv_string = "local_date_time, data_value, variable_id, site_id\n"
    self.data_values.each do |dv|
      temp_array = Array.new()
      temp_array<< dv.local_date_time.to_i.to_s 
      temp_array<< dv.data_value.to_s 
      temp_array<< dv.variable_id.to_s 
      temp_array<< dv.site_id.to_s 
      csv_string = csv_string + temp_array.join(',') + '\n'
    end
    csv_string
  end
  
  def protovis_json
    json_array = Array.new()
    self.data_values.each do |dv|
      temp_hash = Hash.new()
      temp_hash[:local_date_time] = dv.local_date_time.to_i
      temp_hash[:data_value] = dv.data_value
      temp_hash[:variable_id] = dv.variable_id
      temp_hash[:site_id] = dv.site_id
      json_array << temp_hash
    end
    json_array.to_json
  end
end
