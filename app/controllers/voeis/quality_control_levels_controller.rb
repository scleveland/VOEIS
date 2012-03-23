require 'responders/rql'

class QualityControlLevelsController  < InheritedResources::Base
  rescue_from ActionView::MissingTemplate, :with => :invalid_page
  responders :rql
  defaults  :route_collection_name => 'quality_control_levels',
            :route_instance_name => 'quality_control_level',
            :collection_name => 'quality_control_levels',
            :instance_name => 'quality_control_level',
            :resource_class => Voeis::QualityControlLevel

  has_widgets do |root|
    root << widget(:versions)
    root << widget(:edit_cv)
  end

  # GET /variables/new
  def new
    @quality_control_level = Voeis::QualityControlLevel.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  # POST /variables
  def create
    @quality_control_level = Voeis::QualityControlLevel.new(params[:quality_control_level])
    respond_to do |format|
      if @quality_control_level.save
        flash[:notice] = 'Quality Control Level was successfully created.'
        format.json do
          render :json => @quality_control_level.as_json, :callback => params[:jsoncallback]
        end
        format.html { (redirect_to(new_quality_control_level_path())) }
      else
        format.html { render :action => "new" }
      end
    end
  end
  def show
    
  end

  # LOCAL: QualityControlLevel entries
  def index
    if User.current.nil? || User.current.system_role.name!='Administrator'
      flash[:notice] = 'You have inadequate permissions for this operation.'
      redirect_to(project_path(@project))
    end
    ### LOCAL: QUALITY CONTROL LEVEL
    @global = true
    @cv_data = Voeis::QualityControlLevel.all
    @cv_data = @cv_data.map{|d| d.attributes.update({:used=>false})}
    @cv_title = 'Quality Control Level'
    @cv_title2 = 'quality_control_level'
    @cv_title2cv = 'quality_control_level'
    @cv_id = 'id'
    @cv_name = 'quality_control_level_code'
    @cv_columns = [{:field=>"id", :label=>"ID", :width=>"25px", :filterable=>false, :formatter=>"", :style=>""},
                  {:field=>"quality_control_level_code", :label=>"Quality Control Level", :width=>"100px", :filterable=>true, :formatter=>"", :style=>""},
                  {:field=>"definition", :label=>"Definition", :width=>"", :filterable=>true, :formatter=>"", :style=>""},
                  {:field=>"explanation", :label=>"Explanation", :width=>"", :filterable=>true, :formatter=>"", :style=>""},
                  {:field=>"updated_at", :label=>"Updated", :width=>"80px", :filterable=>true, :formatter=>"dateTime", :style=>""}]
    @copy_columns = [{:field=>"id", :label=>"ID", :width=>"25px", :filterable=>false, :formatter=>"", :style=>""},
                  {:field=>"quality_control_level_code", :label=>"Quality Control Level", :width=>"100px", :filterable=>true, :formatter=>"", :style=>""},
                  {:field=>"definition", :label=>"Definition", :width=>"", :filterable=>true, :formatter=>"", :style=>""},
                  {:field=>"explanation", :label=>"Explanation", :width=>"", :filterable=>true, :formatter=>"", :style=>""},
                  {:field=>"updated_at", :label=>"Updated", :width=>"80px", :filterable=>true, :formatter=>"dateTime", :style=>""}]
    @cv_form = [{:field=>"id", :type=>"-IH", :required=>"", :style=>""},
                  {:field=>"idx", :type=>"-XH", :required=>"", :style=>""},
                  {:field=>"Quality Control Level", :type=>"-LL", :required=>"", :style=>""},
                  {:field=>"quality_control_level_code", :type=>"1B-STB", :required=>"true", :style=>""},
                  {:field=>"Definition", :type=>"2B-LL", :required=>"false", :style=>""},
                  {:field=>"definition", :type=>"1B-STA", :required=>"false", :style=>""}]
                  {:field=>"Explanation", :type=>"2B-LL", :required=>"false", :style=>""},
                  {:field=>"explanation", :type=>"1B-STA", :required=>"false", :style=>""}]
    render 'voeis/cv_index.html.haml'
  end

  ### LOCAL: QUALITY CONTROL HISTORY!
  def versions
    @global = false
    @project = parent
    #@cv_item = Voeis::QualityControlLevel.get(params[:id])
    #@cv_versions = @cv_item.versions
    @cv_item = @project.managed_repository{Voeis::QualityControlLevel.get(params[:id])}
    #@cv_versions = @project.managed_repository{Voeis::VerticalDatumCV.get(params[:id]).versions}
    @cv_versions = @project.managed_repository.adapter.select('SELECT * FROM voeis_quality_control_level_versions WHERE id=%s ORDER BY updated_at DESC'%@cv_item.id)
    #@cv_versions = @project.managed_repository{@cv_item.versions_array}
    @cv_title = 'Quality Control Level'
    @cv_title2 = 'quality_control_level'
    @cv_name = 'quality_control_level_code'
    @cv_term = 'quality_control_level_code'
    @cv_id = 'id'

    @cv_refs = []

    @cv_properties = [
      #{:label=>"Version", :name=>"version"},
      #{:label=>"ID", :name=>"id"},
      {:label=>"Quality Control Code", :name=>"quality_control_level_code"},
      {:label=>"Definition", :name=>"definition"},
      {:label=>"Explanation", :name=>"explanation"}
      ]
    render 'spatial_references/versions.html.haml'
  end

  def invalid_page
    redirect_to(:back)
  end
end