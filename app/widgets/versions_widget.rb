class VersionsWidget < Apotomo::Widget
  responds_to_event :submit, :with=>:update_site

  def display(options = {})
    @item = options[:item]
    @versions = options[:versions]
    #@item_title = options[:item_title]
    #@item_title2 = options[:item_title2]
    @unique_id = options[:unique_id]
    @unique_jsid = options[:unique_jsid]
    @item_refs = options[:item_refs]
    @ver_properties = options[:properties]
    @restore_callback = options[:restore_callback]
    ####
    @current_user = options[:user]
    #@auth = !@current_user.nil? && @current_user.projects.include?(@project)
    #@root_url = options[:root_url]
    #@id = UUIDTools::UUID.timestamp_create
    skip_prop = [:deleted_at]
    ####
    #@project = parent
    #@site =  parent.managed_repository{Voeis::Site.get(params[:id])}
    #@versions = parent.managed_repository{Voeis::Site.get(params[:id]).versions}
    ####
    @versions_ref = []
    @versions_items = []
    version_number = @versions.count
    temp = {}
    temp[:version] = 0
    temp[:version_ttl] = 'Current'
    temp[:version_id] = '%s-ver000'%[@unique_id]
    temp[:version_ts] = @item.updated_at.strftime('%Y-%m-%d %H:%M:%S')
    temp[:updated_comment] = @item.updated_comment
    temp[:provenance_comment] = @item.provenance_comment
    @versions_ref << temp
    temp[:dirty] = @item.get_dirty
    @versions.properties.each{|prop| temp[prop.name] = @item[prop.name] unless skip_prop.include?(prop.name)}
    refs = @item_refs.shift
    refs.each{|k,v| temp[k] = v} unless refs.nil?
    upd_user = User.get(@item.updated_by)
    temp[:updated_by_name] = upd_user.nil? ? '-' : '%s (%s)'%[upd_user.name,upd_user.login]
    @versions_items << temp
    @versions.each{|ver|
      temp = {}
      temp[:version] = version_number
      temp[:version_ttl] = 'Version %s'%version_number
      temp[:version_id] = '%s-ver%03d'%[@unique_id,version_number]
      temp[:version_ts] = ver.updated_at.strftime('%Y-%m-%d %H:%M:%S')
      temp[:updated_comment] = ver.updated_comment
      temp[:provenance_comment] = ver.provenance_comment
      @versions_ref << temp
      temp[:dirty] = @item.get_dirty(ver.updated_comment)
      @versions.properties.each{|prop| temp[prop.name] = ver[prop.name] unless skip_prop.include?(prop.name)}
      refs = @item_refs.shift
      refs.each{|k,v| temp[k] = v} unless refs.nil?
      upd_user = User.get(ver.updated_by)
      temp[:updated_by_name] = upd_user.nil? ? '-' : '%s (%s)'%[upd_user.name,upd_user.login]
      version_number-=1
      @versions_items << temp
    }
    ####
    

    @xver_properties = [
#      {:label=>"Version", :name=>"version"},
#      {:label=>"Site ID", :name=>"id"},
      {:label=>"Name", :name=>"name"},
      {:label=>"Code", :name=>"code"},
      {:label=>"Latitude", :name=>"latitude"},
      {:label=>"Longitude", :name=>"longitude"},
      {:label=>"Lat/Long Datum", :name=>"lat_long_datum"},
      {:label=>"Elevation", :name=>"elevation_m"},
      {:label=>"Local X", :name=>"local_x"},
      {:label=>"Local Y", :name=>"local_y"},
      {:label=>"Local Projection", :name=>"local_projection"},
      {:label=>"Vertical Datum", :name=>"vertical_datum"},
      {:label=>"Position Accuracy", :name=>"pos_accuracy_m"},
      {:label=>"State", :name=>"state"},
      {:label=>"County", :name=>"county"},
      {:label=>"Description", :name=>"description"},
      {:label=>"Comments", :name=>"comments"},
      {:label=>"HIS ID", :name=>"his_id"},
      {:label=>"Updated By", :name=>"updated_by_name"},
      {:label=>"Update Comment", :name=>"updated_comment"},
      {:label=>"Provenance Comment", :name=>"provenance_comment"}
      ]
    ###


    render
  end
  
private
  def setup
    #@test = options[:test]
  end
end
