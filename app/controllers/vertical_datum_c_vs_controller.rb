class VerticalDatumCVsController < InheritedResources::Base
  rescue_from ActionView::MissingTemplate, :with => :invalid_page

  has_widgets do |root|
    root << widget(:versions)
    root << widget(:edit_cv)
  end


  # GLOBAL: GET /vertical_datum_c_vs/new
  def new
    @vertical_datum = Voeis::VerticalDatumCV.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  # GLOBAL: POST /vertical_datum_c_vs
  def create
    @vertical_datum = Voeis::VerticalDatumCV.new(params[:vertical_datum_c_v])
    
    respond_to do |format|
      if @vertical_datum.save
        format.html do
          flash[:notice] = 'Vertical Datum was successfully created.'
          redirect_to(new_vertical_datum_c_v_path())
        end
        format.json do
          render :json => @vertical_datum.as_json, :callback => params[:jsoncallback]
        end
      else
        flash[:error] = 'Vertical Datum create FAILED!'
        #format.html { render :action => "new" }
        redirect_to(vertical_datum_c_v_path())
      end
    end
  end

  # GLOBAL: PUT /vertical_datum_c_vs
  def update
    vertical_datum = Voeis::VerticalDatumCV.get(params[:vertical_datum_c_v][:id])
    #debugger
    
    params[:vertical_datum_c_v].each do |key, value|
      vertical_datum[key] = value.blank? ? nil : value
    end
    vertical_datum.updated_at = Time.now
    
    respond_to do |format|
      if vertical_datum.save
        format.html {
          flash[:notice] = 'Vertical Datum was successfully updated.'
          redirect_to(vertical_datum_c_v_path())
        }
        format.json do
          render :json => vertical_datum.as_json, :callback => params[:jsoncallback]
        end
      else
        format.html { render :action => "update" }
      end
    end
  end

  # GLOBAL: List VerticalDatum entries
  def index
    if User.current.nil? || User.current.system_role.name!='Administrator'
      flash[:notice] = 'You have inadequate permissions for this operation.'
      redirect_to(project_path(@project))
    end
    ### GLOBAL VERTICAL DATUM
    @global = true
    @cv_data = Voeis::VerticalDatumCV.all
    @cv_data = @cv_data.map{|d| d.attributes.update({:used=>false})}
    @cv_title = 'Vertical Datum'
    @cv_title2 = 'global_vertical_datum'
    @cv_title2cv = 'vertical_datum_c_v'
    @cv_id = 'id'
    @cv_name = 'term'
    @cv_columns = [{:field=>"id", :label=>"ID", :width=>"25px", :filterable=>false, :formatter=>"", :style=>""},
                  {:field=>"term", :label=>"Term", :width=>"100px", :filterable=>true, :formatter=>"", :style=>""},
                  {:field=>"definition", :label=>"Definition", :width=>"", :filterable=>true, :formatter=>"", :style=>""},
                  {:field=>"updated_at", :label=>"Updated", :width=>"80px", :filterable=>true, :formatter=>"dateTime", :style=>""}]
    @cv_form = [{:field=>"id", :type=>"-IH", :required=>"", :style=>""},
                  {:field=>"idx", :type=>"-XH", :required=>"", :style=>""},
                  {:field=>"Term", :type=>"-LL", :required=>"", :style=>""},
                  {:field=>"term", :type=>"1B-STB", :required=>"true", :style=>""},
                  {:field=>"Definition", :type=>"2B-LL", :required=>"false", :style=>""},
                  {:field=>"definition", :type=>"1B-STA", :required=>"false", :style=>""}]
    #render 'spatial_references/index.html.haml'
    render 'voeis/cv_index.html.haml'
  end

  def show
    
  end

  # GLOBAL: DELETE /VerticalDatum
  def destroy
    vertical_datum = Voeis::VerticalDatumCV.get(params[:id])
    #debugger
    if vertical_datum.destroy
      respond_to do |format|
        format.html {
          flash[:notice] = 'Vertical Datum was successfully deleted.'
          redirect_to(vertical_datum_path())
        }
        format.json {
          render :json => vertical_datum.id.as_json, :callback => params[:jsoncallback]
        }
      end
    else
      #FAILED!
      #format.html { render :action => "update" }
      error_notice = 'Vertical Datum delete FAILED!'
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
    ### GLOBAL VERTICAL DATUM HISTORY
    @global = true
    @cv_item = Voeis::VerticalDatumCV.get(params[:id])
    @cv_versions = @cv_item.versions.to_a
    @cv_title = 'Vertical Datum'
    @cv_title2 = 'vertical_datum'
    @cv_name = 'term'
    @cv_term = 'term'
    @cv_id = 'id'

    @cv_refs = []

    @cv_properties = [
#      {:label=>"Version", :name=>"version"},
#      {:label=>"ID", :name=>"id"},
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