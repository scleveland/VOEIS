class VersionsWidget < Apotomo::Widget
  responds_to_event :submit, :with=>:update_site

  def display(options = {})
    @item = options[:item]
    @versions = options[:versions]
    #@item_title = options[:item_title]
    #@item_title2 = options[:item_title2]
    @unique_id = options[:unique_id]
    ##@unique_jsid = options[:unique_jsid]
    @parent_id = options[:parent_id]
    @item_refs = options[:item_refs]
    @ver_properties = options[:properties]
    @restore_callback = options[:restore_callback]
    ####
    @current_user = options[:user]
    #@auth = !@current_user.nil? && @current_user.projects.include?(@project)
    #@root_url = options[:root_url]
    #@id = UUIDTools::UUID.timestamp_create
    ####
    @project = options[:project]
    #@site =  parent.managed_repository{Voeis::Site.get(params[:id])}
    #@versions = parent.managed_repository{Voeis::Site.get(params[:id]).versions}
    ####
    @versions_ref = []
    @versions_items = []
    version_number = @versions.count
    #ignore listed properties
    #props = @versions.properties.to_a - [:deleted_at]
    props = @item.class.properties.to_a - [:id,:deleted_at]
    temp = {}
    temp[:version] = 0
    temp[:version_ttl] = "Current"
    temp[:version_id] = "%s-ver000"%@unique_id
    temp[:version_ts] = @item.updated_at.strftime('%Y-%m-%d %H:%M:%S')
    temp[:updated_comment] = @item.updated_comment
    temp[:provenance_comment] = @item.provenance_comment
    @versions_ref << temp
    temp[:dirty] = @item.get_dirty
    props.each{|prop| temp[prop.name] = @item[prop.name]}
    refs = @item_refs.shift
    refs.each{|k,v| temp[k] = v} unless refs.nil?
    upd_user = User.get(@item.updated_by)
    temp[:updated_by_name] = upd_user.nil? ? "-" : "%s (%s)"%[upd_user.name,upd_user.login]
    @versions_items << temp
    @versions.each{|ver|
      temp = {}
      temp[:version] = version_number
      temp[:version_ttl] = "Version %s"%version_number
      temp[:version_id] = "%s-ver%03d"%[@unique_id,version_number]
      #temp[:version_ts] = ver.updated_at.strftime('%Y-%m-%d %H:%M:%S')
      if ver.updated_comment.nil?
        temp[:version_ts] = ver.created_at.strftime('%Y-%m-%d %H:%M:%S')
      else
        temp[:version_ts] = ver.updated_comment[10..28]
      end
      temp[:updated_comment] = ver.updated_comment
      temp[:provenance_comment] = ver.provenance_comment
      @versions_ref << temp
      temp[:dirty] = @item.get_dirty(ver.updated_comment)
      sanitized_props = props.map{|p| p.name}- [:id,:deleted_at]
      sanitized_props.each{|prop| temp[prop] = ver[prop]}
      refs = @item_refs.shift
      refs.each{|k,v| temp[k] = v} unless refs.nil?
      upd_user = User.get(ver.updated_by)
      temp[:updated_by_name] = upd_user.nil? ? '-' : '%s (%s)'%[upd_user.name,upd_user.login]
      version_number-=1
      @versions_items << temp
    }
    @xtra = [
      :created_at,
      :updated_at,
      :updated_by,
      :updated_by_name,
      :updated_comment,
      :version_id,
      :version_ts,
      :version_ttl,
      :dirty]
    ####
    render
  end
  
private
  def setup
    #@test = options[:test]
  end
end
