# -*- coding: utf-8 -*-
# Sites TODO- validate the best practices below
#
# This is a "Monitoring Site Locations"
# The Sites table provides information giving the spatial location at which data values have been
# collected.
# The following rules and best practices should be followed when populating this table:
# * The SiteID field is the primary key, must be a unique integer, and cannot be NULL.  This
# field should be implemented as an auto number/identity field.
# * The SiteCode field must contain a text code that uniquely identifies each site.  The values
# in this field should be unique and can be an alternate key for the table.  SiteCodes cannot
# contain any characters other than A-Z (case insensitive), 0-9, period “.”, dash “-“, and
# underscore “_”.
# * The LatLongDatumID must reference a valid SpatialReferenceID from the
# SpatialReferences controlled vocabulary table.  If the datum is unknown, a default value
# of 0 is used.
# * If the Elevation_m field is populated with a numeric value, a value must be specified in
# the VerticalDatum field.  The VerticalDatum field can only be populated using terms
# from the VerticalDatumCV table.  If the vertical datum is unknown, a value of
# “Unknown” is used.
# * If the LocalX and LocalY fields are populated with numeric values, a value must be
# specified in the LocalProjectionID field.  The LocalProjectionID must reference a valid
# SpatialReferenceID from the SpatialReferences controlled vocabulary table.  If the spatial
# reference system of the local coordinates is unknown, a default value of 0 is used.
#

class Voeis::Site
  include DataMapper::Resource
  include Facet::DataMapper::Resource
  include Yogo::Versioned::DataMapper::Resource

  property :id,                  Serial
  property :code,                String,  :required => true
  property :name,                String,  :required => true, :length => 512
  property :latitude,            Float,   :required => true
  property :longitude,           Float,   :required => true
  property :lat_long_datum_id,   Integer, :required => false
  property :elevation_m,         Float,   :required => false
  #property :vertical_datum,      String,  :required => false
  property :vertical_datum_id,   Integer, :required => false
  property :local_x,             Float,   :required => false
  property :local_y,             Float,   :required => false
  property :local_projection_id, Integer, :required => false
  #property :local_projection,    String,  :required => false
  property :pos_accuracy_m,      Float,   :required => false
  property :state,               String,  :required => true
  property :county,              String,  :required => false
  property :comments,            Text,    :required => false
  property :description,         Text,    :required => false
  property :time_zone_offset,    String,  :required => false, :default => "unknown"

  property :his_id,              Integer, :required => false, :index => true

  yogo_versioned

  validates_uniqueness_of :code

  has n, :data_streams,  :model => "Voeis::DataStream",  :through => Resource
  has n, :sensor_types,  :model => "Voeis::SensorType",  :through => Resource
  has n, :sensor_values, :model => "Voeis::SensorValue", :through => Resource
  has n, :data_values,   :model => "Voeis::DataValue",   :through => Resource
  has n, :samples,       :model => "Voeis::Sample",      :through => Resource
  has n, :variables,     :model => "Voeis::Variable",    :through => Resource
  has n, :deployments,   :model => "Voeis::Deployment",  :through => Resource
  belongs_to  :vertical_datum,    :model => "Voeis::VerticalDatumCV", :child_key=>"vertical_datum_id", :required=>false
  belongs_to  :local_projection,  :model => "Voeis::SpatialReference", :child_key=>"local_projection_id", :required=>false
  belongs_to :lat_long_datum, :model => "Voeis::SpatialReference", :child_key=>"lat_long_datum_id", :required=>false
  #has 1,  :vertical_datum,    :model => "Voeis::VerticalDatumCV",    :child_key=>"vertical_datum_id"
  #has 1,  :local_projection,  :model => "Voeis::LocalProjectionCV",  :child_key=>"local_projection_id"

  #has 1, :lat_long_datum, :model=>"Voes::LatLongDatumCV"
  alias :site_name  :name
  alias :site_name= :name=

  alias :site_code  :code
  alias :site_code= :code=

  before :save, :update_associations
  
  #
  #  @returns[:Nokogiri:XML::Builder] :xml a nokogiri xml document
  def self.wml_header
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.siteResponse("xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance", "xmlns:xsd"=>"http://www.w3.org/2001/XMLSchema", "xmlns"=>"http://www.cuahsi.org/waterML/1.1/"){
        xml.queryInfo {
          xml.creationTime DateTime.now
          xml.criteria("MethodCalled"=>"GetSites")
          xml.note  "All Sites"
        }
      }
    end
    builder.doc
  end
   

  # 
  # @params[Nokogiri::XML::Builder] :xml
  def wml_body(doc = nil)
    @repo = self.repository
    @project_name = ""
    DataMapper.repository("default") do
      @project_name = Project.get(@repo.name.to_s.gsub('_','-').chop).id
    end
    unless doc
      doc =Nokogiri::XML::Document.new
    end
    builder = Nokogiri::XML::Builder.with(doc.at('siteResponse')) do |xml|
      xml.site{
        xml.siteInfo{
          xml.siteName  self.name
          xml.siteCode(self.code, :network=>@project_name, :siteID=>self.id)
          xml.geoLocation{
            xml.geogLocation("xsi:type"=>"LatLonPointType", :srs=> self.lat_long_datum ? self.lat_long_datum.srs_name : "WGS84"){
              xml.latitude self.latitude
              xml.longitude self.longitude
            }
            xml.localSiteXY(:projectionInformation => self.local_projection ? self.local_projection.srs_name : ""){
              xml.X  self.local_x
              xml.Y  self.local_y
            }
          }
          xml.elevation_m  self.elevation_m
          xml.verticalDatum  self.vertical_datum
          xml.siteProperty(self.county, :name=>"County")
          xml.siteProperty(self.state, :name => "State")
          xml.siteProperty(self.comments, :name => "Site Comments")
          xml.siteProperty(self.pos_accuracy_m, :name => "PosAccuracy_m")
        }
      }
    end 
    builder.doc
  end
  
  def update_associations
    debugger
    if !self.vertical_datum_id.nil? && self.vertical_datum_id != 0
      puts "Booyah" 
      @vert_datum_global = DataMapper.repository(:default){Voeis::VerticalDatumCV.get(self.vertical_datum_id)}
      if @vert_datum_global.nil?
        self.provenance_comment += " [Vertical Datum (id=%s) NO LONGER EXISTS!]"%self.vertical_datum_id
        self.vertical_datum = nil
      else
        self.vertical_datum = Voeis::VerticalDatumCV.first_or_create(:id=>@vert_datum_global.id,
                                               :term=>@vert_datum_global.term,
                                               :definition=>@vert_datum_global.definition)
      end
    end
    
    puts "HHEYE"
    puts self.code
    puts self.vertical_datum_id
    if !self.local_projection_id.nil? && self.local_projection_id !=0
      puts "HECKYA"
      @local_proj_global = DataMapper.repository(:default){Voeis::SpatialReference.get(self.local_projection_id)}
      if @local_proj_global.nil?
        self.provenance_comment += " [Local Projection (id=%s) NO LONGER EXISTS!]"%self.local_projection_id
        self.local_projection = nil
      else
        self.local_projection = Voeis::SpatialReference.first_or_create(:id=>@local_proj_global.id,
                                            :srs_id => @local_proj_global.srs_id,
                                            :srs_name=>@local_proj_global.srs_name,
                                            :is_geographic =>@local_proj_global.is_geographic,
                                            :notes=>@local_proj_global.notes)
      end
    end
    if !self.lat_long_datum_id.nil? && self.lat_long_datum_id !=0
      puts "HECKYA"
      @lat_long_datum_global = DataMapper.repository(:default){Voeis::SpatialReference.get(self.lat_long_datum_id)}
      if @lat_long_datum_global.nil?
        self.provenance_comment += " [Lat/Long Datum (id=%s) NO LONGER EXISTS!]"%self.lat_long_datum_id
        self.lat_long_datum = nil
      else
        self.lat_long_datum = Voeis::SpatialReference.first_or_create(:id=>@lat_long_datum_global.id,
                                            :srs_id => @lat_long_datum_global.srs_id,
                                            :srs_name=>@lat_long_datum_global.srs_name,
                                            :is_geographic =>@lat_long_datum_global.is_geographic,
                                            :notes=>@lat_long_datum_global.notes)
      end
    end
  end

  def versions_array
    self.versions.to_a
  end
  
  def fetch_time_zone_offset
    require "geonames"
    zone = Geonames::WebService.timezone self.latitude, self.longitude
    self.time_zone_offset = zone.gmt_offset
    self.save!
  end
  
  def load_from_his
    his_sites = repository(:his){ His::Site.all }
    his_sites.each do |his_s|
      if self.first(:his_id => his_s.id).nil?
        create_from_his(his_s.id)
      end
    end
  end

  def create_from_his(id)
    his_s = repository(:his){ His::Site.get(id) }
    my_site = Voeis::Site.new(:his_id => his_s.id,
                       :site_code => his_s.site_code,
                       :site_name  => his_s.site_name,
                       :latitude  => his_s.latitude,
                       :longitude  => his_s.longitude,
                       :lat_long_datum_id => his_s.lat_long_datum_id,
                       :elevation_m   => his_s.elevation_m,
                       :vertical_datum  => his_s.vertical_datum,
                       :local_x  => his_s.local_x,
                       :local_y  => his_s.local_y,
                       :local_projection_id  => his_s.local_projection_id,
                       :pos_accuracy_m  => his_s.pos_accuracy_m,
                       :state  => his_s.state,
                       :county  => his_s.county,
                       :comments  => his_s.comments)
    my_site.save
  end

  def store_to_his
    new_his_site = His::Site.first_or_create(:site_code => site_code, :site_name  => site_name,
                                              :latitude  => latitude,  :longitude  => longitude,
                                              :lat_long_datum_id => lat_long_datum_id,
                                              :elevation_m   => elevation_m,
                                              :vertical_datum  => vertical_datum,
                                              :local_x  => local_x,    :local_y  => local_y,
                                              :local_projection_id  => local_projection_id,
                                              :pos_accuracy_m  => pos_accuracy_m,
                                              :state  => state,        :county  => county,
                                              :comments  => comments)
    his_id = new_his_site.id
    save
    new_his_site
  end
  
  def update_site_data_catalog
    self.variables.each do |var|
      #entry = Voeis::SiteDataCatalog.first_or_create(:site_id => self.id, :variable_id => var.id)
      #sql = "SELECT data_value_id FROM voeis_data_value_variables WHERE variable_id = #{var.id} INTERSECT SELECT data_value_id FROM voeis_data_value_sites WHERE site_id = #{self.id}"
      sql = "SELECT data_value_id FROM voeis_data_values WHERE variable_id = #{var.id} AND site_id = #{self.id}"
      results = repository.adapter.select(sql)
      if results.length > 0
        entry = Voeis::SiteDataCatalog.first_or_create(:site_id => self.id, :variable_id => var.id)
        entry.record_number = results.length
        sql = "SELECT * FROM voeis_data_values WHERE id IN #{results.to_s.gsub('[','(').gsub(']',')')} ORDER BY local_date_time"
        dresults = repository.adapter.select(sql)
        entry.starting_timestamp = dresults.first[:local_date_time]#(var.data_values & self.data_values).first(:order=>[:local_date_time]).local_date_time
        entry.ending_timestamp = dresults.last[:local_date_time] #(var.data_values & self.data_values).last(:order=>[:local_date_time]).local_date_time
        entry.valid?
        puts entry.errors.inspect()
        entry.save!
      end
    end #end each
  end
  
  #accepts an array of varialbes that should be associated with the site.
  def update_site_data_catalog_variables(variables)
    variables.each do |var|
      #entry = Voeis::SiteDataCatalog.first_or_create(:site_id => self.id, :variable_id => var.id)
      #sql = "SELECT data_value_id FROM voeis_data_value_variables WHERE variable_id = #{var.id} INTERSECT SELECT data_value_id FROM voeis_data_value_sites WHERE site_id = #{self.id}"
      sql = "SELECT data_value_id FROM voeis_data_values WHERE variable_id = #{var.id} AND site_id = #{self.id}"
      results = repository.adapter.select(sql)
      if results.length > 0
        entry = Voeis::SiteDataCatalog.first_or_create(:site_id => self.id, :variable_id => var.id)
        entry.record_number = results.length
        sql = "SELECT * FROM voeis_data_values WHERE id IN #{results.to_s.gsub('[','(').gsub(']',')')} ORDER BY local_date_time"
        dresults = repository.adapter.select(sql)
        entry.starting_timestamp = dresults.first[:local_date_time]#(var.data_values & self.data_values).first(:order=>[:local_date_time]).local_date_time
        entry.ending_timestamp = dresults.last[:local_date_time] #(var.data_values & self.data_values).last(:order=>[:local_date_time]).local_date_time
        entry.valid?
        puts entry.errors.inspect()
        entry.save!
      end
    end #end each
  end
  
end

