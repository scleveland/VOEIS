class Voeis::SpatialReferencesController < Voeis::BaseController
  rescue_from ActionView::MissingTemplate, :with => :invalid_page

  has_widgets do |root|
    root << widget(:versions)
  end


  # LOCAL: GET /SpatialReference/new
  def new
    @spatial_reference = parent.managed_repository{Voeis::SpatialReference.new}

    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  # LOCAL: POST /SpatialReference
  def create
    #@spatial_reference = parent.managed_repository{Voeis::SpatialReference.new(params[:spatial_reference])}
    #@spatial_reference = parent.managed_repository{Voeis::SpatialReference.with_deleted(Voeis::SpatialReference.first_or_create(:id=>params[:spatial_reference][:id],
    #                                                      :srs_id=>params[:spatial_reference][:srs_id],
    #                                                      :srs_name=>params[:spatial_reference][:srs_name],
    #                                                      :is_geographic=>params[:spatial_reference][:is_geographic],
    #                                                      :notes=>params[:spatial_reference][:notes],
    #                                                      :provenance_comment=>params[:spatial_reference][:provenance_comment],
    #                                                      :deleted_at=>nil))}
    
    @project = parent
    @project.managed_repository{
      @spatial_reference = Voeis::SpatialReference.with_deleted{Voeis::SpatialReference.get(params[:spatial_reference][:id])}
      if @spatial_reference.nil?
        @spatial_reference = Voeis::SpatialReference.create(:id=>params[:spatial_reference][:id],
                                  :srs_id=>params[:spatial_reference][:srs_id],
                                  :srs_name=>params[:spatial_reference][:srs_name],
                                  :is_geographic=>params[:spatial_reference][:is_geographic],
                                  :notes=>params[:spatial_reference][:notes],
                                  :provenance_comment=>params[:spatial_reference][:provenance_comment])
      else
        #@spatial_reference.deleted_at  #need to reference 'deleted_at' because of lazy loading
        @spatial_reference.update(:id=>params[:spatial_reference][:id],
                                  :srs_id=>params[:spatial_reference][:srs_id],
                                  :srs_name=>params[:spatial_reference][:srs_name],
                                  :is_geographic=>params[:spatial_reference][:is_geographic],
                                  :notes=>params[:spatial_reference][:notes],
                                  :provenance_comment=>params[:spatial_reference][:provenance_comment],
                                  :deleted_at=>nil)
      end
    
      #params[:spatial_reference].each do |key, value|
      #  @spatial_reference[key] = value.blank? ? nil : value
      #end
    
      respond_to do |format|
        #if @spatial_reference.save
          format.html do
            flash[:notice] = 'Local Projection was successfully created.'
            redirect_to(spatial_reference_path())
          end
          format.json do
            render :json => @spatial_reference.as_json, :callback => params[:jsoncallback]
          end
        #else
        #  flash[:error] = 'Local Projection create FAILED!'
        #  #format.html { render :action => "new" }
        #  redirect_to(spatial_reference_path())
        #end
      end
    }
  end

  # LOCAL: PUT /SpatialReference
  def update
    @project = parent
    @project.managed_repository{
      spatial_reference = Voeis::SpatialReference.get(params[:spatial_reference][:id])
    
      params[:spatial_reference].each do |key, value|
        spatial_reference[key] = value.blank? ? nil : value
      end
      spatial_reference.updated_at = Time.now
    
      respond_to do |format|
        if spatial_reference.save
          format.html do
            flash[:notice] = 'Spatial Reference was successfully updated.'
            redirect_to(spatial_reference_path())
          end
          format.json do
            render :json => spatial_reference.as_json, :callback => params[:jsoncallback]
          end
        else
          format.html { render :action => "update" }
        end
      end
    }
  end

  # LOCAL: List SpatialReference entries
  def index
    ### LOCAL SPATIAL REFERENCE
    @project = parent
    if User.current.nil? || 
        !@project.users.include?(User.current) ||
        !User.current.has_role?('Principal Investigator',@project) &&
        !User.current.has_role?('Data Manager',@project)
      flash[:notice] = 'You have inadequate permissions for this operation.'
      redirect_to('/'+@project.id)
    else
      @global = false
      @cv_data0 = @project.managed_repository{Voeis::SpatialReference.all}
      @cv_data = @cv_data0.map{|d| 
        d.attributes.update({:used=>(!@project.sites.first(:lat_long_datum_id=>d[:id]).nil? || 
          !@project.sites.first(:local_projection_id=>d[:id]).nil?)})}
      @copy_data = Voeis::SpatialReference.all(:id.not=>@cv_data0.collect(&:id)) #, :order=>[:srs_name.asc])
      #@copy_data = @copy_data.map{|d| d.attributes.update({:used=>(!@project.sites.first(:lat_long_datum_id=>d[:id]).nil?||!@project.sites.first(:local_projection_id=>d[:id]).nil?)})}
      @cv_title = 'Spatial Reference'
      @cv_title2 = 'spatial_reference'
      @cv_id = 'id'
      @cv_name = 'srs_name'
      @cv_columns = [{:field=>"id", :label=>"ID", :width=>"5%", :filterable=>false, :formatter=>"", :style=>""},
                    {:field=>"srs_name", :label=>"Source Name", :width=>"25%", :filterable=>true, :formatter=>"", :style=>""},
                    {:field=>"srs_id", :label=>"Source ID", :width=>"10%", :filterable=>true, :formatter=>"", :style=>""},
                    {:field=>"is_geographic", :label=>"GEO", :width=>"6%", :filterable=>true, :formatter=>"trueFalse", :style=>""},
                    {:field=>"notes", :label=>"Notes", :width=>"", :filterable=>true, :formatter=>"", :style=>""},
                    {:field=>"used", :label=>"USED", :width=>"6%", :filterable=>true, :formatter=>"trueFalse", :style=>""},
                    {:field=>"updated_at", :label=>"Updated", :width=>"15%", :filterable=>true, :formatter=>"dateTime", :style=>""}]
      @copy_columns = [{:field=>"id", :label=>"ID", :width=>"7%", :filterable=>false, :formatter=>"", :style=>""},
                    {:field=>"srs_name", :label=>"Source Name", :width=>"16%", :filterable=>true, :formatter=>"", :style=>""},
                    {:field=>"srs_id", :label=>"Source ID", :width=>"12%", :filterable=>true, :formatter=>"", :style=>""},
                    {:field=>"is_geographic", :label=>"GEO", :width=>"7%", :filterable=>true, :formatter=>"trueFalse", :style=>""},
                    {:field=>"notes", :label=>"Notes", :width=>"", :filterable=>true, :formatter=>"", :style=>""},
                    {:field=>"updated_at", :label=>"Updated", :width=>"18%", :filterable=>true, :formatter=>"dateTime", :style=>""}]
      render 'spatial_references/index.html.haml'
    end
  end


  def show
    
  end

  # LOCAL: DELETE /SpatialReference
  def destroy
    spatial_reference = parent.managed_repository{Voeis::SpatialReference.get(params[:id])}
    #CHECK IF USED...
    if !@project.sites.first(:lat_long_datum_id=>spatial_reference.id).nil? ||
      !@project.sites.first(:local_projection_id=>spatial_reference.id).nil?
      error_notice = 'This Spatial Reference is IN USE!'
    else
      error_notice = ''
    end
    if error_notice!='' || !spatial_reference.destroy
      #FAILED!
      #format.html { render :action => "update" }
      error_notice = 'Spatial Reference delete FAILED!' if error_notice==''
      respond_to do |format|
        format.html {
          flash[:error] = error_notice
          redirect_to(spatial_reference_path())
        }
        format.json {
          render :json=>{:id=>spatial_reference.id,:errors=>[error_notice]}.as_json, :callback=>params[:jsoncallback]
        }
      end
    else
      respond_to do |format|
        format.html {
          flash[:notice] = 'Spatial Reference was successfully deleted.'
          redirect_to(spatial_reference_path())
        }
        format.json {
          render :json=>{:id=>spatial_reference.id}.as_json, :callback=>params[:jsoncallback]
        }
      end
    end
  end
  
  #HISTORY!
  def versions
    ### LOCAL SPATIAL REFERENCE HISTORY
    @global = false
    @project = parent
    @cv_item = @project.managed_repository{Voeis::SpatialReference.get(params[:id])}
    @cv_versions = @project.managed_repository{Voeis::SpatialReference.get(params[:id]).versions}
    #@cv_versions = @cv_item.versions
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
      {:label=>"Gergraphic", :name=>"is_geo_string"},
      {:label=>"Notes", :name=>"notes"}
      ]
    
    render 'spatial_references/versions.html.haml'
  end

  def invalid_page
    redirect_to(:back)
  end
end