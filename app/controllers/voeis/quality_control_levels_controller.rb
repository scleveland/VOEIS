class Voeis::QualityControlLevelsController  < Voeis::BaseController
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
  
  ### LOCAL: POST /quality_control_level
  def create
    @project = parent
    @project.managed_repository{
      cvparams = params
      cvparams = params[:quality_control_level] if !params[:quality_control_level].nil?
      @quality_control_level = Voeis::QualityControlLevel.with_deleted{Voeis::QualityControlLevel.get(cvparams[:id])}
      if @quality_control_level.nil?
        @quality_control_level = Voeis::QualityControlLevel.create(:id=>cvparams[:id],
                                :quality_control_level_code=>cvparams[:quality_control_level_code],
                                :definition=>cvparams[:definition],
                                :explanation=>cvparams[:explanation],
                                :provenance_comment=>cvparams[:provenance_comment])
      else
        #@vertical_datum.deleted_at  #need to reference 'deleted_at' because of lazy loading
        @quality_control_level.update(
                              :quality_control_level_code=>cvparams[:quality_control_level_code],
                              :definition=>cvparams[:definition],
                              :explanation=>cvparams[:explanation],
                              :provenance_comment=>cvparams[:provenance_comment],
                              :deleted_at=>nil)
      end
    
      respond_to do |format|
        format.json do
          render :json => @quality_control_level.as_json, :callback => params[:jsoncallback]
        end
        format.html do
          flash[:notice] = 'Quality Control Level was successfully created.'
          redirect_to(new_quality_control_level_path())
        end
      end
    }
  end
  
  ### LOCAL: PUT /quality_control_level
  def update
    @project = parent
    @project.managed_repository{
      if params[:quality_control_level].nil?
        @quality_control_level = Voeis::QualityControlLevel.get(params[:id].to_i)
        cvparams = params
      else
        @quality_control_level = Voeis::QualityControlLevel.get(params[:quality_control_level][:id].to_i)
        cvparams = params[:quality_control_level]
      end
      logger.info '### CVPARAMS ###'
      logger.info cvparams.to_json
      cvparams.each do |key, value|
        @quality_control_level[key] = value.blank? ? nil : value
      end
      @quality_control_level.updated_at = Time.now
      
      respond_to do |format|
        if @quality_control_level.save
          format.json do
            render :json => @quality_control_level.as_json, :callback => params[:jsoncallback]
          end
          format.html do
            flash[:notice] = 'Quality Control Level was successfully updated.'
            redirect_to(new_quality_control_level_path())
          end
        else
          format.html { render :action => "new" }
        end
      end
    }
  end

  ### LOCAL: DELETE /quality_control_level
  def destroy
    @project = parent
    @project.managed_repository{
      quality_control_level = Voeis::VariableNameCV.get(params[:id])
      #debugger
      if !quality_control_level.destroy
        #FAILED!
        #format.html { render :action => "update" }
        error_notice = 'Quality Control Level delete FAILED!'
        respond_to do |format|
          format.html {
            flash[:error] = error_notice
            redirect_to(quality_control_level_path())
          }
          format.json {
            render :json=>{:id=>quality_control_level.id,:errors=>[error_notice]}.as_json, :callback=>params[:jsoncallback]
          }
        end
      else
        respond_to do |format|
          format.html {
            flash[:notice] = 'Quality Control Level was successfully deleted.'
            redirect_to(quality_control_level_path())
          }
          format.json {
            render :json => {:id=>quality_control_level.id}.as_json, :callback=>params[:jsoncallback]
          }
        end
      end
    }
  end
  
  def show
  end

  ### LOCAL: GET /quality_control_level -- QualityControlLevel entries
  def index
    @project = parent
    if User.current.nil? || User.current.system_role.name!='Administrator'
      flash[:notice] = 'You have inadequate permissions for this operation.'
      redirect_to(project_path(@project))
    end
    ### LOCAL: QUALITY CONTROL LEVEL
    @global = true
    @cv_data0 = @project.managed_repository{Voeis::QualityControlLevel.all}
    #@cv_data = @cv_data0.map{|d| d.attributes.update({:used=>!@project.sites.first(:variable_name_id=>d[:id]).nil?})}
    @cv_data = @cv_data0.map{|d| d.attributes.update({:used=>false})}
    @copy_data = Voeis::QualityControlLevel.all(:id.not=>@cv_data0.collect(&:id)) #, :order=>[:quality_control_level_code.asc])
    @cv_title = 'Quality Control Level'
    @cv_title2 = 'quality_control_level'
    @cv_title2cv = 'quality_control_level'
    @cv_id = 'id'
    @cv_name = 'quality_control_level_code'
    @cv_columns = [{:field=>"id", :label=>"ID", :width=>"25px", :filterable=>false, :formatter=>"", :style=>""},
                  {:field=>"quality_control_level_code", :label=>"Quality Control Level", :width=>"200px", :filterable=>true, :formatter=>"", :style=>""},
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
                  {:field=>"quality_control_level_code", :type=>"1B-SNB", :required=>"true", :style=>""},
                  {:field=>"Definition", :type=>"2B-LL", :required=>"false", :style=>""},
                  {:field=>"definition", :type=>"1B-STA", :required=>"false", :style=>""},
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
    #@cv_versions = @project.managed_repository{@cv_item.versions_array}
    @cv_versions = @project.managed_repository.adapter.select('SELECT * FROM voeis_quality_control_level_versions WHERE id=%s ORDER BY updated_at DESC'%@cv_item.id)
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
    #render 'spatial_references/versions.html.haml'
    render 'voeis/cv_versions.html.haml'
  end

  def invalid_page
    redirect_to(:back)
  end
end