class ValueTypeCVsController < InheritedResources::Base
  rescue_from ActionView::MissingTemplate, :with => :invalid_page

  has_widgets do |root|
    root << widget(:versions)
    root << widget(:edit_cv)
  end


  ### GLOBAL: GET /value_type_c_vs/new
  def new
    @value_type = Voeis::ValueTypeCV.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  ### GLOBAL: POST /value_type_c_vs
  def create
    @value_type = Voeis::ValueTypeCV.new(params[:value_type_c_v])
    respond_to do |format|
      if @value_type.save
        format.html do
          flash[:notice] = 'Value Type was successfully created.'
          redirect_to(new_value_type_c_v_path())
        end
        format.json do
          render :json => @value_type.as_json, :callback => params[:jsoncallback]
        end
      else
        format.html { render :action => "new" }
      end
    end
  end

  ### GLOBAL: PUT /value_type_c_vs
  def update
    cvparams = params
    cvparams = params[:value_type_c_v] if !params[:value_type_c_v].nil?
    @value_type = Voeis::ValueTypeCV.get(cvparams[:id])
    #logger.info '### CVPARAMS ###'
    #logger.info cvparams.to_json
    #logger.info '### VALUE-TYPE ###'
    #logger.info @value_type.to_json
    cvparams.each do |key, value|
      @value_type[key] = value.blank? ? nil : value
    end
    @value_type.updated_at = Time.now
    
    respond_to do |format|
      if @value_type.save
        format.html do
          flash[:notice] = 'Value Type was successfully updated.'
          redirect_to(new_value_type_c_v_path()) 
        end
        format.json do
          render :json => @value_type.as_json, :callback => params[:jsoncallback]
        end
      else
        format.html { render :action => "new" }
      end
    end
  end

  ### GLOBAL: DELETE /value_type_c_vs
  def destroy
    value_type = Voeis::ValueTypeCV.get(params[:id])
    #debugger
    if !value_type.destroy
      #FAILED!
      #format.html { render :action => "update" }
      error_notice = 'Value Type delete FAILED!'
      respond_to do |format|
        format.html {
          flash[:error] = error_notice
          redirect_to(value_type_path())
        }
        format.json {
          render :json=>{:id=>value_type.id,:errors=>[error_notice]}.as_json, :callback=>params[:jsoncallback]
        }
      end
    else
      respond_to do |format|
        format.html {
          flash[:notice] = 'Value Type was successfully deleted.'
          redirect_to(value_type_path())
        }
        format.json {
          render :json => {:id=>value_type.id}.as_json, :callback=>params[:jsoncallback]
        }
      end
    end
  end
  
  def show
  end
  
  ### GLOBAL: GET /value_type_c_vs -- List ValueType entries
  def index
    if User.current.nil? || User.current.system_role.name!='Administrator'
      flash[:notice] = 'You have inadequate permissions for this operation.'
      redirect_to(project_path(@project))
      return
    end
    ### GLOBAL ValueType
    @global = true
    @cv_data0 = Voeis::ValueTypeCV.all
    @cv_data = @cv_data0.map{|d| d.attributes.update({:used=>false})}
    @cv_title = 'Value Type'
    @cv_title2 = 'global_value_type'
    @cv_title2cv = 'value_type_c_v'
    @cv_id = 'id'
    @cv_name = 'term'
    @cv_columns = [{:field=>"id", :label=>"ID", :width=>"25px", :filterable=>false, :formatter=>"", :style=>""},
                  {:field=>"term", :label=>"Term", :width=>"180px", :filterable=>true, :formatter=>"", :style=>""},
                  {:field=>"definition", :label=>"Definition", :width=>"", :filterable=>true, :formatter=>"", :style=>""},
                  {:field=>"updated_at", :label=>"Updated", :width=>"130px", :filterable=>true, :formatter=>"dateTime", :style=>""}]
    @cv_form = [{:field=>"id", :type=>"-IH", :required=>"", :style=>""},
                  {:field=>"idx", :type=>"-XH", :required=>"", :style=>""},
                  {:field=>"Term", :type=>"-LL", :required=>"", :style=>""},
                  {:field=>"term", :type=>"1B-STB", :required=>"true", :style=>""},
                  {:field=>"Definition", :type=>"2B-LL", :required=>"false", :style=>""},
                  {:field=>"definition", :type=>"1B-STA", :required=>"false", :style=>""}]
    render 'voeis/cv_index.html.haml'
  end

  ### GLOBAL: ValueType HISTORY!
  def versions
    @global = true
    @cv_item = Voeis::ValueTypeCV.get(params[:id])
    @cv_versions = @cv_item.versions.to_a
    @cv_title = 'Value Type'
    @cv_title2 = 'global_value_type'
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