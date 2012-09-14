class SpatialReferencesController < InheritedResources::Base
  rescue_from ActionView::MissingTemplate, :with => :invalid_page

  has_widgets do |root|
    root << widget(:versions)
    root << widget(:edit_cv)
  end


  # GLOBAL: GET /SpatialReference/new
  def new
    @spatial_reference = Voeis::SpatialReference.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  # GLOBAL: POST /SpatialReference
  def create
    @spatial_reference = Voeis::SpatialReference.new(params[:spatial_reference])
    
    respond_to do |format|
      if @spatial_reference.save
        format.html do
          flash[:notice] = 'Local Projection was successfully created.'
          redirect_to(new_spatial_reference_path())
        end
        format.json do
          render :json => @spatial_reference.as_json, :callback => params[:jsoncallback]
        end
      else
        flash[:error] = 'Local Projection create FAILED!'
        #format.html { render :action => "new" }
        redirect_to(spatial_reference_path())
      end
    end
  end

  # GLOBAL: PUT /SpatialReference
  def update
    spatial_reference = Voeis::SpatialReference.get(params[:spatial_reference][:id])
    #debugger
    
    cvparams = params[:spatial_reference]
    cvparams.each do |prop,value| 
      #v = value.strip
      #cvparams[prop] = nil if v=='NaN' || v=='null'
      cvparams[prop] = value.blank? ? nil : value
    end
    cvparams[:is_geographic] = cvparams[:is_geographic]=~(/(true|t|yes|y|1)$/i) ? true : false
    cvparams.each do |prop,value|
      spatial_reference[prop] = value
    end
    spatial_reference.updated_at = Time.now
    
    respond_to do |format|
      if spatial_reference.save
        format.html {
          flash[:notice] = 'Spatial Reference was successfully updated.'
          redirect_to(spatial_reference_path())
        }
        format.json do
          render :json => spatial_reference.as_json, :callback => params[:jsoncallback]
        end
      else
        format.html { render :action => "update" }
      end
    end
  end

  # GLOBAL: List SpatialReference entries
  def index
    if User.current.nil? || User.current.system_role.name!='Administrator'
      flash[:notice] = 'You have inadequate permissions for this operation.'
      redirect_to(project_path(@project))
      return
    end
    ### GLOBAL SPATIAL REFERENCE
    @global = true
    @cv_data = Voeis::SpatialReference.all
    @cv_data = @cv_data.map{|d| d.attributes.update({:used=>false})}
    @cv_title = 'Spatial Reference'
    @cv_title2 = 'global_spatial_reference'
    @cv_title2cv = 'spatial_reference'
    @cv_id = 'id'
    @cv_name = 'srs_name'
    @cv_columns = [{:field=>"id", :label=>"ID", :width=>"25px", :filterable=>false, :formatter=>"", :style=>""},
                  {:field=>"srs_name", :label=>"Source Name", :width=>"110px", :filterable=>true, :formatter=>"", :style=>""},
                  {:field=>"srs_id", :label=>"Source ID", :width=>"80px", :filterable=>true, :formatter=>"", :style=>""},
                  {:field=>"is_geographic", :label=>"GEO", :width=>"40px", :filterable=>true, :formatter=>"trueFalse", :style=>""},
                  {:field=>"notes", :label=>"Notes", :width=>"", :filterable=>true, :formatter=>"", :style=>""},
                  {:field=>"updated_at", :label=>"Updated", :width=>"130px", :filterable=>true, :formatter=>"dateTime", :style=>""}]
    @cv_form = [{:field=>"id", :type=>"-IH", :required=>"", :style=>""},
                  {:field=>"idx", :type=>"-XH", :required=>"", :style=>""},
                  {:field=>"Source ID", :type=>"-LL", :required=>"", :style=>""},
                  {:field=>"srs_id", :type=>"1B-INB", :required=>"true", :style=>""},
                  {:field=>"Source Name", :type=>"2B-LL", :required=>"", :style=>""},
                  {:field=>"srs_name", :type=>"1B-STB", :required=>"true", :style=>""},
                  {:field=>"is_geographic", :type=>"6S-BCK", :required=>"false", :style=>""},
                  {:field=>"Geographic", :type=>"1S-LL", :required=>"", :style=>""},
                  {:field=>"Notes", :type=>"2B-LL", :required=>"", :style=>""},
                  {:field=>"notes", :type=>"1B-STA", :required=>"false", :style=>""}]
    #render 'spatial_references/index.html.haml'
    render 'voeis/cv_index.html.haml'
  end

  def show
    
  end

  # GLOBAL: DELETE /SpatialReference
  def destroy
    spatial_reference = Voeis::SpatialReference.get(params[:id])
    #debugger
    puts params
    if spatial_reference.destroy
      respond_to do |format|
        format.html {
          flash[:notice] = 'Spatial Reference was successfully deleted.'
          redirect_to(spatial_reference_path())
        }
        format.json {
          render :json => spatial_reference.id.as_json, :callback => params[:jsoncallback]
        }
      end
    else
      #FAILED!
      #format.html { render :action => "update" }
      error_notice = 'Spatial Reference delete FAILED!'
      respond_to do |format|
        format.html {
          flash[:notice] = error_notice
          redirect_to(spatial_reference_path())
        }
        format.json {
          render :json=>{:id=>spatial_reference.id,:errors=>[error_notice]}.as_json, :callback=>params[:jsoncallback]
        }
      end
    end
  end
  
  #HISTORY!
  def versions
    ### GLOBAL SPATIAL REFERENCE HISTORY
    @global = true
    @cv_item = Voeis::SpatialReference.get(params[:id])
    @cv_versions = @cv_item.versions.to_a
    @cv_title = 'Spatial Reference'
    @cv_title2 = 'spatial_reference'
    @cv_term = 'srs_name'
    @cv_name = 'srs_name'
    @cv_id = 'id'
    
    @cv_refs = []
    temp = {}
    temp[:is_geo_string] = @cv_item.is_geographic ? 'True' : 'False'
    @cv_refs << temp
    @cv_versions.each{|ver| 
      temp = {}
      temp[:is_geo_string] = @cv_item.is_geographic ? 'True' : 'False'
      @cv_refs << temp
    }
    
    @cv_properties = [
#      {:label=>"Version", :name=>"version"},
#      {:label=>"ID", :name=>"id"},
      {:label=>"Source Name", :name=>"srs_name"},
      {:label=>"Source ID", :name=>"srs_id"},
      {:label=>"Geographic", :name=>"is_geo_string", :contains=>["is_geographic"]},
      {:label=>"Notes", :name=>"notes"}
      ]
    
    @cv_columns = [{:field=>"id", :label=>"ID", :width=>"5%", :filterable=>false, :formatter=>"", :style=>""},
                  {:field=>"srs_name", :label=>"Source Name", :width=>"15%", :filterable=>true, :formatter=>"", :style=>""},
                  {:field=>"srs_id", :label=>"Source ID", :width=>"10%", :filterable=>true, :formatter=>"", :style=>""},
                  {:field=>"is_geographic", :label=>"GEO", :width=>"5%", :filterable=>true, :formatter=>"trueFalse", :style=>""},
                  {:field=>"notes", :label=>"Notes", :width=>"", :filterable=>true, :formatter=>"", :style=>""},
                  {:field=>"updated_at", :label=>"Updated", :width=>"15%", :filterable=>true, :formatter=>"dateTime", :style=>""}]
    
    render 'voeis/cv_versions.html.haml'
  end

  def invalid_page
    redirect_to(:back)
  end
end