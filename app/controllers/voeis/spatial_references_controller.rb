class Voeis::SpatialReferencesController < Voeis::BaseController
  rescue_from ActionView::MissingTemplate, :with => :invalid_page

  has_widgets do |root|
    root << widget(:versions)
    root << widget(:edit_cv)
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
      spatial_reference = Voeis::SpatialReference.get(params[:spatial_reference][:id].to_i)
    
      cvparams = params[:spatial_reference]
      cvparams.each do |prop,value| 
        #v = value.strip
        #cvparams[prop] = nil if v=='NaN' || v=='null'
        cvparams[prop] = value.blank? ? nil : value
      end
      
      #logger.info '### PARAMS ID ###'
      #logger.info params[:spatial_reference][:id]
      #logger.info '### CV-PARAMS ###'
      #logger.info cvparams
      cvparams[:is_geographic] = cvparams[:is_geographic]=~(/(true|t|yes|y|1)$/i) ? true : false
      
      #logger.info '### UPDATED CV-PARAMS ###'
      #logger.info cvparams
      #logger.info '### SPATIAL REFERENCE ###'
      #logger.info spatial_reference.to_hash
      
      cvparams.each do |prop,value|
        spatial_reference[prop] = value
      end
      spatial_reference.updated_at = Time.now
    
      logger.info '### SAVE SPATIAL REFERENCE ###'
      logger.info spatial_reference.to_hash
      
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
      redirect_to(project_path(@project))
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
      @cv_title2cv = 'spatial_reference'
      @cv_id = 'id'
      @cv_name = 'srs_name'
      @cv_columns = [{:field=>"id", :label=>"ID", :width=>"25px", :filterable=>false, :formatter=>"", :style=>""},
                    {:field=>"srs_name", :label=>"Source Name", :width=>"110px", :filterable=>true, :formatter=>"", :style=>""},
                    {:field=>"srs_id", :label=>"Source ID", :width=>"80px", :filterable=>true, :formatter=>"", :style=>""},
                    {:field=>"is_geographic", :label=>"GEO", :width=>"40px", :filterable=>true, :formatter=>"trueFalse", :style=>""},
                    {:field=>"notes", :label=>"Notes", :width=>"", :filterable=>true, :formatter=>"", :style=>""},
                    {:field=>"used", :label=>"USED", :width=>"40px", :filterable=>true, :formatter=>"trueFalse", :style=>""},
                    {:field=>"updated_at", :label=>"Updated", :width=>"80px", :filterable=>true, :formatter=>"dateTime", :style=>""}]
      @copy_columns = [{:field=>"id", :label=>"ID", :width=>"7%", :filterable=>false, :formatter=>"", :style=>""},
                    {:field=>"srs_name", :label=>"Source Name", :width=>"16%", :filterable=>true, :formatter=>"", :style=>""},
                    {:field=>"srs_id", :label=>"Source ID", :width=>"12%", :filterable=>true, :formatter=>"", :style=>""},
                    {:field=>"is_geographic", :label=>"GEO", :width=>"7%", :filterable=>true, :formatter=>"trueFalse", :style=>""},
                    {:field=>"notes", :label=>"Notes", :width=>"", :filterable=>true, :formatter=>"", :style=>""},
                    {:field=>"updated_at", :label=>"Updated", :width=>"18%", :filterable=>true, :formatter=>"dateTime", :style=>""}]
      @cv_form = [{:field=>"id", :type=>"-IH", :required=>"", :style=>""},
                    {:field=>"idx", :type=>"-XH", :required=>"", :style=>""},
                    {:field=>"Source Name", :type=>"-LL", :required=>"", :style=>""},
                    {:field=>"srs_name", :type=>"1B-STB", :required=>"true", :style=>""},
                    {:field=>"Source ID", :type=>"2B-LL", :required=>"", :style=>""},
                    {:field=>"srs_id", :type=>"1B-INB", :required=>"true", :style=>""},
                    {:field=>"is_geographic", :type=>"6S-BCK", :required=>"false", :style=>""},
                    {:field=>"Geographic", :type=>"1S-LL", :required=>"", :style=>""},
                    {:field=>"Notes", :type=>"2B-LL", :required=>"", :style=>""},
                    {:field=>"notes", :type=>"1B-STA", :required=>"false", :style=>""}]
      #render 'spatial_references/index.html.haml'
      render 'voeis/cv_index.html.haml'
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
    #@project.managed_repository{
      #@cv_item = Voeis::SpatialReference.get(params[:id])
      #@cv_versions = @cv_item.versions.to_a
      @cv_item = @project.managed_repository{Voeis::SpatialReference.get(params[:id])}
      #@cv_versions = @project.managed_repository{Voeis::SpatialReference.get(params[:id]).versions}
      #@cv_versions = @cv_versions.to_a
      #@cv_versions = @cv_item.versions.to_a
      @cv_versions = @project.managed_repository.adapter.select('SELECT * FROM voeis_spatial_reference_versions WHERE id=%s ORDER BY updated_at DESC'%@cv_item.id)
      ##@cv_versions = @project.managed_repository{@cv_item.versions_array}
      @cv_title = 'Spatial Reference'
      @cv_title2 = 'spatial_reference'
      @cv_term = 'srs_name'
      @cv_name = 'srs_name'
      @cv_id = 'id'

      @cv_refs = []
      temp = {}
      temp[:is_geo_string] = @cv_item.is_geographic ? 'True' : 'False'
      @cv_refs << temp
      #debugger
      @cv_versions.each{|ver| 
        temp = {}
        temp[:is_geo_string] = ver.is_geographic ? 'True' : 'False'
        @cv_refs << temp
      }

      @cv_properties = [
        #{:label=>"Version", :name=>"version"},
        #{:label=>"ID", :name=>"id"},
        {:label=>"Source Name", :name=>"srs_name"},
        {:label=>"Source ID", :name=>"srs_id"},
        {:label=>"Geographic", :name=>"is_geo_string", :contains=>["is_geographic"]},
        {:label=>"Notes", :name=>"notes"}
        ]
    #}
    render 'spatial_references/versions.html.haml'
  end

  def invalid_page
    redirect_to(:back)
  end
end