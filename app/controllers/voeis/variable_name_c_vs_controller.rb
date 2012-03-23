class VariableNameCVsController < ApplicationController
  rescue_from ActionView::MissingTemplate, :with => :invalid_page

  has_widgets do |root|
    root << widget(:versions)
    root << widget(:edit_cv)
  end


  # GET /variables/new
  def new
    @variable_name = Voeis::VariableNameCV.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  ### GLOBAL POST /variables
  def create
    if params[:variable_name_c_v].nil?
      @variable_name = Voeis::VariableNameCV.new(:term=> params[:term], :definition => params[:definition])
    else
      @variable_name = Voeis::VariableNameCV.new(params[:variable_name_c_v])
    end
    respond_to do |format|
      if @variable_name.save
        flash[:notice] = 'Variable Name was successfully created.'
        format.html { (redirect_to(new_variable_name_c_v_path())) }
        format.json do
          render :json => @variable_name.as_json, :callback => params[:jsoncallback]
        end
      else
        format.html { render :action => "new" }
      end
    end
  end

  def show

  end

  # LOCAL: List VariableName entries
  def index
    if User.current.nil? || User.current.system_role.name!='Administrator'
      flash[:notice] = 'You have inadequate permissions for this operation.'
      redirect_to(project_path(@project))
    end
    ### LOCAL VARIABLE NAME
    @global = false
    @cv_data = Voeis::VariableNameCV.all
    @cv_data = @cv_data.map{|d| d.attributes.update({:used=>false})}
    @cv_title = 'Variable Name'
    @cv_title2 = 'global_variable_name'
    @cv_title2cv = 'variable_name_c_v'
    @cv_id = 'id'
    @cv_name = 'term'
    @cv_columns = [{:field=>"id", :label=>"ID", :width=>"25px", :filterable=>false, :formatter=>"", :style=>""},
                  {:field=>"term", :label=>"Term", :width=>"100px", :filterable=>true, :formatter=>"", :style=>""},
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

  ### LOCAL: VARIABLE-NAME HISTORY!
  def versions
    @global = false
    @project = parent
    @cv_item = @project.managed_repository{Voeis::VariableNameCV.get(params[:id])}
    #@cv_versions = @project.managed_repository{Voeis::VerticalDatumCV.get(params[:id]).versions}
    @cv_versions = @project.managed_repository.adapter.select('SELECT * FROM voeis_variable_name_cv_versions WHERE id=%s ORDER BY updated_at DESC'%@cv_item.id)
    #@cv_versions = @project.managed_repository{@cv_item.versions_array}
    @cv_title = 'Variable Name'
    @cv_title2 = 'variable_name'
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
    render 'spatial_references/versions.html.haml'
  end

  def invalid_page
    redirect_to(:back)
  end
end