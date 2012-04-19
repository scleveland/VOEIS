class SampleTypeCVsController < InheritedResources::Base
  rescue_from ActionView::MissingTemplate, :with => :invalid_page

  has_widgets do |root|
    root << widget(:versions)
    root << widget(:edit_cv)
  end


  ### GLOBAL: GET /sample_type_c_vs/new
  def new
    @sample_type = Voeis::SampleTypeCV.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  ### GLOBAL: POST /sample_type_c_vs
  def create
    if params[:sample_type_c_v].nil?
      @sample_type = Voeis::SampleTypeCV.new(:term=> params[:term], :definition => params[:definition])
    else
      @sample_type = Voeis::SampleTypeCV.new(params[:sample_type_c_v])
    end
    respond_to do |format|
      if @sample_type.save
        format.html do
          flash[:notice] = 'Sample Type was successfully created.'
          redirect_to(new_sample_type_c_v_path())
        end
        format.json do
          render :json => @sample_type.as_json, :callback => params[:jsoncallback]
        end
      else
        format.html { render :action => "new" }
      end
    end
  end

  ### GLOBAL: PUT /sample_type_c_vs
  def update
    cvparams = params
    cvparams = params[:sample_type_c_v] if !params[:sample_type_c_v].nil?
    @sample_type = Voeis::SampleTypeCV.get(cvparams[:id])
    cvparams.each do |key, value|
      @sample_type[key] = value.blank? ? nil : value
    end
    @sample_type.updated_at = Time.now
    
    respond_to do |format|
      if @sample_type.save
        format.html do
          flash[:notice] = 'Sample Type was successfully updated.'
          redirect_to(new_sample_type_c_v_path()) 
        end
        format.json do
          render :json => @sample_type.as_json, :callback => params[:jsoncallback]
        end
      else
        format.html { render :action => "new" }
      end
    end
  end

  ### GLOBAL: DELETE /sample_type_c_vs
  def destroy
    sample_type = Voeis::SampleTypeCV.get(params[:id])
    #debugger
    if !sample_type.destroy
      #FAILED!
      #format.html { render :action => "update" }
      error_notice = 'Sample Type delete FAILED!'
      respond_to do |format|
        format.html {
          flash[:error] = error_notice
          redirect_to(sample_type_path())
        }
        format.json {
          render :json=>{:id=>sample_type.id,:errors=>[error_notice]}.as_json, :callback=>params[:jsoncallback]
        }
      end
    else
      respond_to do |format|
        format.html {
          flash[:notice] = 'Sample Type was successfully deleted.'
          redirect_to(sample_type_path())
        }
        format.json {
          render :json => {:id=>sample_type.id}.as_json, :callback=>params[:jsoncallback]
        }
      end
    end
  end
  
  def show
  end

  ### GLOBAL: GET /sample_type_c_vs -- List SampleType entries
  def index
    if User.current.nil? || User.current.system_role.name!='Administrator'
      flash[:notice] = 'You have inadequate permissions for this operation.'
      redirect_to(project_path(@project))
    end
    ### GLOBAL SampleType
    @global = true
    @cv_data0 = Voeis::SampleTypeCV.all
    @cv_data = @cv_data0.map{|d| d.attributes.update({:used=>false})}
    @cv_title = 'Sample Type'
    @cv_title2 = 'global_sample_type'
    @cv_title2cv = 'sample_type_c_v'
    @cv_id = 'id'
    @cv_name = 'term'
    @cv_columns = [{:field=>"id", :label=>"ID", :width=>"25px", :filterable=>false, :formatter=>"", :style=>""},
                  {:field=>"term", :label=>"Term", :width=>"180px", :filterable=>true, :formatter=>"", :style=>""},
                  {:field=>"definition", :label=>"Definition", :width=>"", :filterable=>true, :formatter=>"", :style=>""},
                  {:field=>"updated_at", :label=>"Updated", :width=>"80px", :filterable=>true, :formatter=>"dateTime", :style=>""}]
    @cv_form = [{:field=>"id", :type=>"-IH", :required=>"", :style=>""},
                  {:field=>"idx", :type=>"-XH", :required=>"", :style=>""},
                  {:field=>"Term", :type=>"-LL", :required=>"", :style=>""},
                  {:field=>"term", :type=>"1B-STB", :required=>"true", :style=>""},
                  {:field=>"Definition", :type=>"2B-LL", :required=>"false", :style=>""},
                  {:field=>"definition", :type=>"1B-STA", :required=>"false", :style=>""}]
    render 'voeis/cv_index.html.haml'
  end

  ### GLOBAL: SampleType HISTORY!
  def versions
    @global = true
    @cv_item = Voeis::SampleTypeCV.get(params[:id])
    @cv_versions = @cv_item.versions.to_a
    @cv_title = 'Sample Type'
    @cv_title2 = 'global_sample_type'
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