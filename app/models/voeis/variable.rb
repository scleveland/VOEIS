# -*- coding: utf-8 -*-
# Variables
#
# This is apart of "Variables"
# The Variables table lists the full descriptive information about what variables have been
# measured.
# The following rules and best practices should be followed when populating this table:
# * The VariableID field is the primary key, must be a unique integer, and cannot be NULL.
# This field should be implemented as an auto number/identity field.
# * The VariableCode field must be unique and serves as an alternate key for this table.
# Variable codes can be arbitrary, or they can use an organized system.  VaraibleCodes
# cannot contain any characters other than A-Z (case insensitive), 0-9, period “.”, dash “-“,
# and underscore “_”.
# * The VariableName field must reference a valid Term from the VariableNameCV
# controlled vocabulary table.
# * The Speciation field must reference a valid Term from the SpeciationCV controlled
# vocabulary table.  A default value of “Not Applicable” is used where speciation does not
# apply.  If the speciation is unknown, a value of “Unknown” can be used.
# * The VariableUnitsID field must reference a valid UnitsID from the UnitsTable controlled
# vocabulary table.
# * Only terms from the SampleMediumCV table can be used to populate the
# SampleMedium field.  A default value of “Unknown” is used where the sample medium
# is unknown.
# * Only terms from the ValueTypeCV table can be used to populate the ValueType field.  A
# default value of “Unknown” is used where the value type is unknown.
# * The default for the TimeSupport field is 0.  This corresponds to instantaneous values.  If
# the TimeSupport field is set to a value other than 0, an appropriate TimeUnitsID must be
# specified.  The TimeUnitsID field can only reference valid UnitsID values from the Units
# controlled vocabulary table.  If the TimeSupport field is set to 0, any time units can be
# used (i.e., seconds, minutes, hours, etc.), however a default value of 103 has been used,
# which corresponds with hours.
# * Only terms from the DataTypeCV table can be used to populated the DataType field.  A
# default value of “Unknown” can be used where the data type is unknown.
# * Only terms from the GeneralCategoryCV table can be used to populate the
# GeneralCategory field.  A default value of “Unknown” can be used where the general
# category is unknown.
# * The NoDataValue should be set such that it will never conflict with a real observation
# value.  For example a NoDataValue of -9999 is valid for water temperature because we
# would never expect to measure a water temperature of -9999.  The default value for this
# field is -9999.

class Voeis::Variable
  include DataMapper::Resource
  include Facet::DataMapper::Resource
  include Yogo::Versioned::DataMapper::Resource

  property :id,                Serial
  property :variable_code,     String,  :required => true, :length => 512
  property :variable_name,     String,  :required => true, :length => 512
  property :speciation,        String,  :required => true, :default => 'Not Applicable', :length => 512
  property :variable_units_id, Integer, :required => true

  property :sample_medium,     String,  :required => true, :default => 'Unknown', :length => 512
  property :value_type,        String,  :required => true, :default =>'Unknown', :length => 512
  property :quality_control,   Integer, :required => true, :default => 0
  property :is_regular,        Boolean, :required => true, :default => false
  property :time_support,      Float,   :required => true, :default => 1.0
  property :time_units_id,     Integer, :required => true, :default => 103
  property :data_type,         String,  :required => true, :default => 'Unknown', :length => 512
  property :general_category,  String,  :required => true, :default => 'Unknown', :length => 512
  property :no_data_value,     String,   :required => true, :default => "-9999"
  property :detection_limit,   Float,   :required => false
  property :value_type,        String, :required => true, :default=>"Unknown"
  property :lab_method_id,     Integer, :required => false
  property :lab_id,             Integer, :required => false
  property :field_method_id,     Integer, :required => false
  property :spatial_units_id,   Integer,  :required => false
  property :spatial_offset_type,   String,  :required => false, :length => 512
  property :spatial_offset_value, Float,    :required => false
  property :logger_type,        String,   :required =>false, :length => 512
  property :logger_id,          String,   :required => false, :length => 512
  property :sensor_type,        String,   :required => false, :length => 512
  property :sensor_id,          String,   :required => false, :length => 512
  
  
  property :his_id,            Integer, :required => false, :index => true

  yogo_versioned

  has n, :data_stream_columns, :model => "Voeis::DataStreamColumn", :through => Resource
  has n, :sensor_types,        :model => "Voeis::SensorType",       :through => Resource
  has n, :units,               :model => "Voeis::Unit",             :through => Resource
  has n, :data_values,         :model => "Voeis::DataValue",        :through => Resource
  has n, :sites,               :model => "Voeis::Site",             :through => Resource
  has n, :samples,             :model => "Voeis::Sample",           :through => Resource
  has n, :data_type_cvs,       :model => "Voeis::DataTypeCV",       :through => Resource
  has n, :general_category_cvs,:model => "Voeis::GeneralCategoryCV",:through => Resource
  has n, :sample_type_csv,     :model => "Voeis::SampleTypeCV",     :through => Resource
  has n, :speciation_cvs,      :model => "Voeis::SpeciationCV",     :through => Resource
  has n, :value_type_cvs,      :model => "Voeis::ValueTypeCV",      :through => Resource
  has n, :variable_name_cvs,   :model => "Voeis::VariableNameCV",   :through => Resource

  belongs_to :variable_units,     :model => "Voeis::Unit"
  belongs_to :time_units,         :model => "Voeis::Unit"
  belongs_to :lab_method,         :model => "Voeis::LabMethod"
  belongs_to :lab,                :model => "Voeis::Lab"
  belongs_to :field_method,       :model => "Voeis::FieldMethod"
  belongs_to :spatial_units,      :model => "Voeis::Unit"
  
  has n, :meta_tags, :model => 'Voeis::MetaTag', :through => Resource
  has n, :spatial_offsets,      :model => "Voeis::SpatialOffset",    :through => Resource
  has n, :instruments, :model => "Voeis::Instrument",    :through => Resource
  
  
  def self.load_from_his
    his_variables = repository(:his){ His::Variable.all }

    his_variables.each do |his_v|
      if self.first(:his_id => his_v.id).nil?
        self.create(:his_id => his_v.id,
                    :variable_name => his_v.variable_name,
                    :variable_code => his_v.variable_code,
                    :speciation => his_v.speciation,
                    :variable_units_id => his_v.variable_units_id,
                    :sample_medium => his_v.sample_medium,
                    :value_type => his_v.value_type,
                    :is_regular => his_v.is_regular,
                    :time_support => his_v.time_support,
                    :time_units_id => his_v.time_units_id,
                    :data_type => his_v.data_type,
                    :general_category => his_v.general_category,
                    :no_data_value => his_v.no_data_value)
      end
    end
  end

  def store_to_his
    var_to_store = self
    if var_to_store.his_valid?
      if var_to_store.his_id.nil?
        new_his_var = His::Variable.new(:variable_name => var_to_store.variable_name,
                                            :variable_code => var_to_store.variable_code,
                                            :speciation => var_to_store.speciation,
                                            :variable_units_id => var_to_store.variable_units_id,
                                            :sample_medium => var_to_store.sample_medium,
                                            :value_type => var_to_store.value_type,
                                            :is_regular => var_to_store.is_regular ? 1 : 0,
                                            :time_support => var_to_store.time_support,
                                            :time_units_id => var_to_store.time_units_id,
                                            :data_type => var_to_store.data_type,
                                            :general_category => var_to_store.general_category,
                                            :no_data_value => var_to_store.no_data_value.valid_float? ? var_to_store.no_data_value.to_f : -9999.0)
        new_his_var.valid?
        puts new_his_var.errors.inspect
        new_his_var.save
        var_to_store.his_id = new_his_var.id
        var_to_store.save
        new_his_var
      else
        His::Variable.get(var_to_store.his_id)
      end
    else
      return nil
    end
  end
  
  def his_valid?
    #if 
    Voeis::SpeciationCV.first(:term=>self.speciation).cv_types.first(:name => "CUAHSI HIS")
      Voeis::VariableNameCV.first(:term=>self.variable_name).cv_types.first(:name => "CUAHSI HIS") #&& 
       Voeis::SampleMediumCV.first(:term=>self.sample_medium).cv_types.first(:name => "CUAHSI HIS") #&&
       Voeis::ValueTypeCV.first(:term=>self.value_type).cv_types.first(:name => "CUAHSI HIS") #&&
       Voeis::DataTypeCV.first(:term=>self.data_type).cv_types.first(:name => "CUAHSI HIS") #&&
       Voeis::GeneralCategoryCV.first(:term=>self.general_category).cv_types.first(:name => "CUAHSI HIS")# &&
       !Voeis::Unit.get(self.variable_units_id).his_id.nil?
    #   return true
    # else
    #   return false
    # end
  end
  
  def self.last_five_site_values(site_id)
      
  end
  
  def last_ten_values_graph(site)
    # #(self.data_values & site.data_values).all(:order=>[:local_date_time], :limit=>10).map{|dv| [dv.local_date_time.to_datetime.to_i, dv.data_value] }
    # sql = "SELECT data_value_id FROM voeis_data_value_variables WHERE variable_id = #{self.id} INTERSECT SELECT data_value_id FROM voeis_data_value_sites WHERE site_id = #{site.id}"
    # results = repository.adapter.select(sql)
    # if results.length != 0
    #   sql = "SELECT * FROM voeis_data_values WHERE id IN #{results.to_s.gsub('[','(').gsub(']',')')} ORDER BY local_date_time DESC LIMIT 10"
      dresults = Voeis::DataValue.all(:site_id => site.id, :variable_id => self.id, :order => [:local_date_time.desc], :limit => 24)
      #dresults = repository.adapter.select(sql)
      dresults.map{|dv| [dv[:local_date_time].to_datetime.to_i*1000, dv[:data_value]]}
    #end
  end  
  
  def last_ten_values(site)
    # sql = "SELECT data_value_id FROM voeis_data_value_variables WHERE variable_id = #{self.id} INTERSECT SELECT data_value_id FROM voeis_data_value_sites WHERE site_id = #{site.id}"
    # results = repository.adapter.select(sql)
    # if results.length != 0
    #   sql = "SELECT * FROM voeis_data_values WHERE id IN #{results.to_s.gsub('[','(').gsub(']',')')} ORDER BY local_date_time DESC LIMIT 10"
    #   dresults = repository.adapter.select(sql)
    dresults = Voeis::DataValue.all(:site_id => site.id, :variable_id => self.id, :order => [:local_date_time.desc], :limit => 24)
      dresults.map{|dv| [dv[:local_date_time].to_datetime, dv[:data_value]]}
      #(self.data_values & site.data_values).all(:order=>[:local_date_time], :limit=>10).map{|dv| [dv.local_date_time.to_datetime, dv.data_value] }
    #end
  end

  def recent_values(site,outcount=12)
    # LAST 12 VALUES / 24 HOURS -or- LAST 12 VALUES
    dresults = Voeis::DataValue.all(:site_id=>site.id, :variable_id=>self.id, :order=>[:local_date_time.desc], :limit=>400)
    unless dresults.empty?
      results = dresults.all(:local_date_time.gt=>dresults[0][:local_date_time]-24.hours)
      if results.length<outcount
        results = dresults[0,outcount]
      else
        inc = results.length/outcount.to_f
        results = results.values_at(*(0..outcount-1).map{|x|(x*inc).round})
      end
      return results
    end
  end
  
  def values(site,outcount=12)
    dresults = Voeis::DataValue.all(:site_id=>site.id, :variable_id=>self.id, :order=>[:local_date_time.desc], :limit=>outcount)
  end
  
  def last_days_values(site,outcount=12)
    # LAST 12 VALUES / 24 HOURS -or- LAST 12 VALUES
    # as ARRAY [ timestamp, data_value, string_value ]
    dresults = self.recent_values(site,outcount)
    unless dresults.nil?
      dresults.map{|dv| [dv[:local_date_time].to_datetime, dv[:data_value], dv[:string_value]]}
    else
      dresults
    end
  end  
  
  def last_days_values_graph(site,outcount=12)
    # LAST 12 VALUES / 24 HOURS -or- LAST 12 VALUES
    dresults = self.recent_values(site,outcount)
    unless dresults.nil?
      dresults.map{|dv| [dv[:local_date_time].to_datetime.to_i*1000, dv[:data_value]]}
    else
      dresults
    end
  end
  
  def values_graph(site,outcount=12)
    # LAST 12 VALUES / 24 HOURS -or- LAST 12 VALUES
    dresults = self.values(site,outcount)
    unless dresults.nil?
      dresults.map{|dv| [dv[:local_date_time].to_datetime.to_i*1000, dv[:data_value]]}
    else
      dresults
    end
  end
  
end
