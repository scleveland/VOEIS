require 'dm-core'
require 'dm-types/uuid'
require 'uuid_json'

require 'yogo/datamapper/repository_manager'

# Top-level data-management container.
#
# Project includes functionality from Yogo::DataMapper::RespositoryManager
# @see http://github.com/yogo/yogo-project/blob/topic/managers/lib/yogo/datamapper/repository_manager.rb
#
#
class Project
  include DataMapper::Resource
  include Yogo::DataMapper::RepositoryManager
  include Facet::DataMapper::Resource

  property :id,               UUID,       :key => true, :default => lambda { |x,y| UUIDTools::UUID.timestamp_create }

  property :name,             String,     :required => true
  property :description,      Text

  property :is_private,       Boolean,    :required => true, :default => false
  property :publish_to_his,   Boolean,    :required => false, :default => false
  property :deleted_at,       ParanoidDateTime

  has n, :memberships, :parent_key => [:id], :child_key => [:project_id], :model => 'Membership'
  has n, :users, :through => :memberships
  has n, :roles, :through => :memberships

  after :create, :give_current_user_membership
  after :create,  :upgrade_global_models
  after :create, :create_data_value_indexes

  before :destroy, :destroy_cleanup
  after :save, :publish_his


  def upgrade_global_models
    DataMapper.auto_upgrade!
  end
  ##
  # Permissions on the object for the user that is passed in
  #
  # @param [User or nil] user To check the permissions for
  # @return [Array] Set of permissions for the current user
  # @author lamb
  # @api semipublic
  def self.permissions_for(user)
    # By default, all users can retrieve projects
    (super << "#{permission_base_name}$retrieve").uniq
  end

  ##
  # Same as above, but for instances instead of classes
  #
  # @param [User or nil] user To check permissions for
  # @return [Array] Set of permissions the current user has
  # @api semipublic
  def permissions_for(user)
    @_permissions_for ||= {}
    @_permissions_for[user] ||= begin
      base_permission = []
      # Default retrieve permissions if project is public
      base_permission += ["#{permission_base_name}$retrieve",
                          "voeis/data_stream$retrieve",
                          "voeis/data_stream_column$retrieve",
                          "voeis/meta_tag$retrieve",
                          "voeis/sensor_type$retrieve",
                          "voeis/sensor_value$retrieve",
                          "voeis/meta_tag$retrieve",
                          "voeis/source$retrieve",
                          "voeis/site$retrieve",
                          "voeis/unit$retrieve",
                          "voeis/variable$retrieve",
                          "voeis/lab_method$retrieve",
                          "voeis/sample$retrieve",
                          "voeis/sample_type_cv$retrieve",
                          "voeis/sample_material$retrieve",
                          "voeis/data_set$retrieve",
                          "voeis/site_data_catalog$retrieve",
                          "voeis/spatial_reference$retrieve",
                          "voeis/vertical_datum_cv$retrieve",
                          "voeis/apiv$retrieve",
                          "voeis/jobs$retrieve",
                          "voeis/search$retrieve",
                          "voeis/script$retrieve",
                          "voeis/data_value$retrieve"] unless self.is_private?
      return base_permission if user.nil?
      (super + base_permission + user.memberships(:project_id => self.id).roles.map{|r| r.actions }).flatten.uniq
    end
  end

  def publish_his
    errors = []
    success = []
    if self.publish_to_his
      sites = self.managed_repository{ Voeis::Site.all }
      sites.each do |site|
        # Store system wide first
        system_site = Voeis::Site.first_or_create(:site_code => site.code,
                                           :site_name  => site.name,
                                           :latitude  => site.latitude,
                                           :longitude  => site.longitude,
                                           :state  => site.state,
                                           :lat_long_datum_id => 1,
                                           :elevation_m   => 0,
                                           :vertical_datum  => "Unknown",
                                           :local_x  => 0.0,
                                           :local_y  => 0.0,
                                           :local_projection_id  => 1,
                                           :pos_accuracy_m  => 1,
                                           :county  => "USA",
                                           :comments  => "comment")
        # Push to HIS
        his_site = system_site.store_to_his
        if his_site
          success << "Site ID:#{system_site.id}, Name: #{system_site.name} successfully save to HIS."
          site.variables.each do |site_variable|
            if site_variable.name != "Timestamp"
              system_variable = Voeis::Variable.first(:variable_code => variable.variable_code, :variable_name => variable.variable_name)
              his_variable = system_variable.store_to_his
              unless his_variable.nil?
                success<< "Varialble ID:#{site_variable.id}, Code: #{site_variable.variable_code}, Name: #{site_variable.variable_name} successfully saved to HIS."
                data_values = Voeis::DataValue.all(:published => false, :order => [:timestamp.asc])
                sources = data_values.sources.all(:fields=>[:id], :unique=>true).uniq
                sources.each{|src| src.store_to_his}
                data_values.each do |val|
                  val.store_to_his(his_site.id, his_variable.id, val.source.his_id)
                end #val
              else
                errors << "Varialble ID:#{site_variable.id}, Code: #{site_variable.variable_code}, Name: #{site_variable.variable_name} was not compatible with HIS confirm that controlled vocabularies are of the CUAHSI HIS type."
              end
            end #if
          end # sensor_type
        else
          errors << "Site ID:#{system_site.id} was not compatible with HIS."
        end# if his_site
      end #site
      email_string= "Your project attempted to publish to HIS"
      puts VoeisMailer.email_user(user.email, "From VOEIS:: Your Project:#{parent.name} HIS publication Notification:", results.to_s)
    end
    
  end

  def self.store_site_to_system(u_id)
    site_to_store = self.managed_repository{Voeis::Site.first(:id => u_id)}
    new_system_site = Voeis::Site.create(:site_code => site_to_store.code,
                                     :site_name  => site_to_store.name,
                                     :latitude  => site_to_store.latitude,
                                     :longitude  => site_to_store.longitude,
                                     :lat_long_datum_id => site_to_store.lat_long_datum_id,
                                     :elevation_m   => site_to_store.elevation_m,
                                     :vertical_datum  => site_to_store.vertical_datum,
                                     :local_x  => site_to_store.local_x,
                                     :local_y  => site_to_store.local_y,
                                     :local_projection_id  => site_to_store.local_projection_id,
                                     :pos_accuracy_m  => site_to_store.pos_accuracy_m,
                                     :state  => site_to_store.state,
                                     :county  => site_to_store.county,
                                     :comments  => site_to_store.comments)
  end

  def update_project_site_data_catalog
    self.managed_repository do
      Voeis::Site.all.each do |site|
        site.update_site_data_catalog
      end
    end
  end
  # Ensure that our common Voeis models are ready to be persisted
  # in the Project#managed_repository.
  # @author Ryan Heimbuch
  manage Voeis::Site
  manage Voeis::SiteDataCatalog
  manage Voeis::DataStream
  manage Voeis::DataStreamColumn
  manage Voeis::MetaTag
  manage Voeis::SensorType
  manage Voeis::SensorValue
  manage Voeis::Source
  manage Voeis::Unit
  manage Voeis::Variable
  manage Voeis::LabMethod
  manage Voeis::Sample
  manage Voeis::SampleMaterial
  manage Voeis::DataValue
  manage Voeis::Apiv
  manage Voeis::DataSet
  def sites
    managed_repository{ Voeis::Site.all }
  end
  
  #fetch all variables from the Projects
  def variables
    managed_repository{ Voeis::Variable.all}
  end
  
    
  private
  
  def destroy_cleanup
    memberships.destroy
  end

  def give_current_user_membership
    unless User.current.nil?
      Membership.create(:user => User.current, :project => self, :role => Role.first(:position => 1))
    end
  end
  
  def create_data_value_indexes
    self.managed_repository do
      begin
        sql = "CREATE INDEX data_value_idx ON voeis_data_values (datatype, local_date_time, site_id, variable_id)"
        repository.adapter.execute(sql)
      rescue
      end
      begin
        sql = "CREATE INDEX data_value_idx_var ON voeis_data_values (variable_id)"
        repository.adapter.execute(sql)
      rescue
      end
      begin
        sql = "CREATE INDEX data_value_idx_site ON voeis_data_values (site_id)"
        repository.adapter.execute(sql)
      rescue
      end
      begin
        sql = "CREATE INDEX data_value_idx_site_var ON voeis_data_values (site_id, variable_id)"
        repository.adapter.execute(sql)
      rescue
      end
      begin
        sql = "CREATE INDEX data_value_idx_time ON voeis_data_values (local_date_time)"
        repository.adapter.execute(sql)
      rescue
      end
      begin
        sql = "CREATE INDEX data_value_idx_site_var_time ON voeis_data_values (local_date_time, site_id, variable_id)"
        repository.adapter.execute(sql)
      rescue
      end
      begin
        sql = "CREATE INDEX data_value_idx_type ON voeis_data_values (datatype)"
        repository.adapter.execute(sql)
      rescue
      end
    end
  end
end # Project
