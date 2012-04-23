class Voeis::DataTypeCVsController < Voeis::BaseController
  rescue_from ActionView::MissingTemplate, :with => :invalid_page

  has_widgets do |root|
    root << widget(:versions)
    root << widget(:edit_cv)
  end


  ### LOCAL: GET /data_type_c_vs/new
  def new
    @data_type = Voeis::DataTypeCV.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  ### LOCAL: POST /data_type_c_vs
  def create
    @project = parent
    @project.managed_repository{
      if params[:data_type_c_v].nil?
        @data_type = Voeis::DataTypeCV.new(:term=> params[:term], :definition => params[:definition])
      else
        @data_type = Voeis::DataTypeCV.new(params[:data_type_c_v])
      end
      respond_to do |format|
        if @data_type.save
          flash[:notice] = 'Data Type was successfully created.'
          format.html { (redirect_to(new_data_type_c_v_path())) }
          format.json do
            render :json => @data_type.as_json, :callback => params[:jsoncallback]
          end
        else
          format.html { render :action => "new" }
        end
      end
    }
  end
  
  ### LOCAL: PUT /data_type_c_vs
  def update
    @project = parent
    @project.managed_repository{
      cvparams = params
      cvparams = params[:data_type_c_v] if !params[:data_type_c_v].nil?
      
      @data_type = Voeis::DataTypeCV.get(cvparams[:id])
      cvparams.each do |key, value|
        @data_type[key] = value.blank? ? nil : value
      end
      @data_type.updated_at = Time.now
      
      respond_to do |format|
        if @data_type.save
          format.html do
            flash[:notice] = 'Data Type was successfully updated.'
            redirect_to(new_data_type_c_v_path()) 
          end
          format.json do
            render :json => @data_type.as_json, :callback => params[:jsoncallback]
          end
        else
          format.html { render :action => "new" }
        end
      end
    }
  end
  
  ### LOCAL: DELETE /data_type_c_vs
  def destroy
    @project = parent
    @project.managed_repository{
      data_type = Voeis::DataTypeCV.get(params[:id])
      #debugger
      if !data_type.destroy
        #FAILED!
        #format.html { render :action => "update" }
        error_notice = 'Data Type delete FAILED!'
        respond_to do |format|
          format.html {
            flash[:error] = error_notice
            redirect_to(data_type_path())
          }
          format.json {
            render :json=>{:id=>data_type.id,:errors=>[error_notice]}.as_json, :callback=>params[:jsoncallback]
          }
        end
      else
        respond_to do |format|
          format.html {
            flash[:notice] = 'Data Type was successfully deleted.'
            redirect_to(data_type_path())
          }
          format.json {
            render :json => {:id=>data_type.id}.as_json, :callback=>params[:jsoncallback]
          }
        end
      end
    }
  end
  
  def show
  end

  ### LOCAL: GET /data_type_c_vs
  def index
    @project = parent
    if User.current.nil? || User.current.system_role.name!='Administrator'
      flash[:notice] = 'You have inadequate permissions for this operation.'
      redirect_to(project_path(@project))
      return
    end
    ### LOCAL DataType
    @global = false
    @cv_data0 = @project.managed_repository{Voeis::DataTypeCV.all}
    #@cv_data = @cv_data0.map{|d| d.attributes.update({:used=>!@project.sites.first(:variable_name_id=>d[:id]).nil?})}
    @cv_data = @cv_data0.map{|d| d.attributes.update({:used=>false})}
    @copy_data = Voeis::DataTypeCV.all(:id.not=>@cv_data0.collect(&:id)) #, :order=>[:term.asc])
    @cv_title = 'Data Type'
    @cv_title2 = 'data_type'
    @cv_title2cv = 'data_type_c_v'
    @cv_id = 'id'
    @cv_name = 'term'
    @cv_columns = [{:field=>"id", :label=>"ID", :width=>"25px", :filterable=>false, :formatter=>"", :style=>""},
                  {:field=>"term", :label=>"Term", :width=>"180px", :filterable=>true, :formatter=>"", :style=>""},
                  {:field=>"definition", :label=>"Definition", :width=>"", :filterable=>true, :formatter=>"", :style=>""},
                  {:field=>"updated_at", :label=>"Updated", :width=>"80px", :filterable=>true, :formatter=>"dateTime", :style=>""}]
    @copy_columns = [{:field=>"id", :label=>"ID", :width=>"5%", :filterable=>false, :formatter=>"", :style=>""},
                  {:field=>"term", :label=>"Term", :width=>"15%", :filterable=>true, :formatter=>"", :style=>""},
                  {:field=>"definition", :label=>"Definition", :width=>"", :filterable=>true, :formatter=>"", :style=>""},
                  {:field=>"updated_at", :label=>"Updated", :width=>"18%", :filterable=>true, :formatter=>"dateTime", :style=>""}]
    @cv_form = [{:field=>"id", :type=>"-IH", :required=>"", :style=>""},
                  {:field=>"idx", :type=>"-XH", :required=>"", :style=>""},
                  {:field=>"Term", :type=>"-LL", :required=>"", :style=>""},
                  {:field=>"term", :type=>"1B-STB", :required=>"true", :style=>""},
                  {:field=>"Definition", :type=>"2B-LL", :required=>"false", :style=>""},
                  {:field=>"definition", :type=>"1B-STA", :required=>"false", :style=>""}]
    render 'voeis/cv_index.html.haml'
  end

  ### LOCAL: DataType HISTORY!
  def versions
    @global = false
    @project = parent
    @cv_item = @project.managed_repository{Voeis::DataTypeCV.get(params[:id])}
    #@cv_versions = @project.managed_repository{Voeis::VerticalDatumCV.get(params[:id]).versions}
    #@cv_versions = @project.managed_repository{@cv_item.versions_array}
    @cv_versions = @project.managed_repository.adapter.select('SELECT * FROM voeis_data_type_cv_versions WHERE id=%s ORDER BY updated_at DESC'%@cv_item.id)
    @cv_title = 'Data Type'
    @cv_title2 = 'data_type'
    @cv_term = 'term'
    @cv_name = 'term'
    @cv_id = 'id'

    @cv_refs = []

    @cv_properties = [
      #{:label=>"Version", :name=>"version"},
      #{:label=>"ID", :name=>"id"},
      {:label=>"Term", :name=>"term"},
      {:label=>"Definition", :name=>"definition"}
    ]
    #render 'spatial_references/versions.html.haml'
    render 'voeis/cv_versions.html.haml'
  end
  
  def invalid_page
    redirect_to(:back)
  end
end