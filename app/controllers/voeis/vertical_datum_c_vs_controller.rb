class Voeis::VerticalDatumCVsController < Voeis::BaseController
  rescue_from ActionView::MissingTemplate, :with => :invalid_page

  has_widgets do |root|
    root << widget(:versions)
    root << widget(:edit_cv)
  end


  # LOCAL: GET /vertical_datum_c_vs/new
  def new
    @vertical_datum = parent.managed_repository{Voeis::VerticalDatumCV.new}

    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  # LOCAL: POST /vertical_datum_c_vs
  def create
    #@vertical_datum = parent.managed_repository{Voeis::VerticalDatumCV.new(params[:vertical_datum_c_v])}
    #@vertical_datum = parent.managed_repository{Voeis::VerticalDatumCV.first_or_create(:id=>params[:vertical_datum_c_v][:id],
    #                                                      :term=>params[:vertical_datum_c_v][:term],
    #                                                      :definition=>params[:vertical_datum_c_v][:definition],
    #                                                      :provenance_comment=>params[:vertical_datum_c_v][:provenance_comment],
    #                                                      :deleted_at=>nil)}
    
    @project = parent
    @project.managed_repository{
      @vertical_datum = Voeis::VerticalDatumCV.with_deleted{Voeis::VerticalDatumCV.get(params[:vertical_datum_c_v][:id])}
      if @vertical_datum.nil?
        @vertical_datum = Voeis::VerticalDatumCV.create(:id=>params[:vertical_datum_c_v][:id],
                                :term=>params[:vertical_datum_c_v][:term],
                                :definition=>params[:vertical_datum_c_v][:definition],
                                :provenance_comment=>params[:vertical_datum_c_v][:provenance_comment])
      else
        #@vertical_datum.deleted_at  #need to reference 'deleted_at' because of lazy loading
        @vertical_datum.update(:id=>params[:vertical_datum_c_v][:id],
                                :term=>params[:vertical_datum_c_v][:term],
                                :definition=>params[:vertical_datum_c_v][:definition],
                                :provenance_comment=>params[:vertical_datum_c_v][:provenance_comment],
                                :deleted_at=>nil)
      end
    
      respond_to do |format|
        #if @vertical_datum.save
        format.html do
          flash[:notice] = 'Vertical Datum was successfully created.'
          redirect_to(vertical_datum_c_v_path())
        end
        format.json do
          render :json => @vertical_datum.as_json, :callback => params[:jsoncallback]
        end
        #else
        #  flash[:error] = 'Vertical Datum create FAILED!'
        #  #format.html { render :action => "new" }
        #  redirect_to(vertical_datum_c_v_path())
        #end
      end
    }
  end
  
  # LOCAL: PUT /vertical_datum_c_vs
  def update
    @project = parent
    @project.managed_repository{
      vertical_datum = Voeis::VerticalDatumCV.get(params[:vertical_datum_c_v][:id])
    
      params[:vertical_datum_c_v].each do |key, value|
        vertical_datum[key] = value.blank? ? nil : value
      end
      vertical_datum.updated_at = Time.now
    
      respond_to do |format|
        if vertical_datum.save
          format.html do
            flash[:notice] = 'Vertical Datum was successfully updated.'
            redirect_to(vertical_datum_c_v_path())
          end
          format.json do
            render :json => vertical_datum.as_json, :callback => params[:jsoncallback]
          end
        else
          format.html { render :action => "update" }
        end
      end
    }
  end

  # LOCAL: List VerticalDatum entries -- GET /vertical_datum_c_vs
  def index
    ### LOCAL VERTICAL DATUM
    @project = parent
    if User.current.nil? || 
        !@project.users.include?(User.current) ||
        (!User.current.has_role?('Principal Investigator',@project) &&
        !User.current.has_role?('Data Manager',@project))
      flash[:notice] = 'You have inadequate permissions for this operation.'
      redirect_to(project_path(@project))
      return
    else
      @global = false
      @cv_data0 = @project.managed_repository{Voeis::VerticalDatumCV.all}
      @cv_data = @cv_data0.map{|d| d.attributes.update({:used=>!@project.sites.first(:vertical_datum_id=>d[:id]).nil?})}
      @copy_data = Voeis::VerticalDatumCV.all(:id.not=>@cv_data0.collect(&:id)) #, :order=>[:term.asc])
      @cv_title = 'Vertical Datum'
      @cv_title2 = 'vertical_datum'
      @cv_title2cv = 'vertical_datum_c_v'
      @cv_id = 'id'
      @cv_name = 'term'
      @cv_columns = [{:field=>"id", :label=>"ID", :width=>"25px", :filterable=>false, :formatter=>"", :style=>""},
                    {:field=>"term", :label=>"Term", :width=>"100px", :filterable=>true, :formatter=>"", :style=>""},
                    {:field=>"definition", :label=>"Definition", :width=>"", :filterable=>true, :formatter=>"", :style=>""},
                    {:field=>"used", :label=>"USED", :width=>"40px", :filterable=>true, :formatter=>"trueFalse", :style=>""},
                    {:field=>"updated_at", :label=>"Updated", :width=>"130px", :filterable=>true, :formatter=>"dateTime", :style=>""}]
      @copy_columns = [{:field=>"id", :label=>"ID", :width=>"5%", :filterable=>false, :formatter=>"", :style=>""},
                    {:field=>"term", :label=>"Term", :width=>"15%", :filterable=>true, :formatter=>"", :style=>""},
                    {:field=>"definition", :label=>"Definition", :width=>"", :filterable=>true, :formatter=>"", :style=>""},
                    {:field=>"updated_at", :label=>"Updated", :width=>"130px", :filterable=>true, :formatter=>"dateTime", :style=>""}]
      @cv_form = [{:field=>"id", :type=>"-XH", :required=>"", :style=>""},
                    {:field=>"idx", :type=>"-XH", :required=>"", :style=>""},
                    {:field=>"Term", :type=>"-LL", :required=>"", :style=>""},
                    {:field=>"term", :type=>"1B-STB", :required=>"true", :style=>""},
                    {:field=>"Definition", :type=>"2B-LL", :required=>"false", :style=>""},
                    {:field=>"definition", :type=>"1B-STA", :required=>"false", :style=>""}]
      #render 'spatial_references/index.html.haml'
      render 'voeis/cv_index.html.haml'
    end
  end


  def show
    
  end

  # LOCAL: DELETE /VerticalDatum
  def destroy
    @project = parent
    @project.managed_repository{
      vertical_datum = Voeis::VerticalDatumCV.get(params[:id])
      #debugger
      #CHECK IF USED...
      if !@project.sites.first(:vertical_datum_id=>vertical_datum.id).nil?
        error_notice = 'This Vertical Datum is IN USE!'
      else
        error_notice = ''
      end
      if error_notice!='' || !vertical_datum.destroy
        #FAILED!
        #format.html { render :action => "update" }
        error_notice = 'Vertical Datum delete FAILED!' if error_notice==''
        respond_to do |format|
          format.html {
            flash[:error] = error_notice
            redirect_to(vertical_datum_path())
          }
          format.json {
            render :json=>{:id=>vertical_datum.id,:errors=>[error_notice]}.as_json, :callback=>params[:jsoncallback]
          }
        end
      else
        respond_to do |format|
          format.html {
            flash[:notice] = 'Vertical Datum was successfully deleted.'
            redirect_to(vertical_datum_path())
          }
          format.json {
            render :json => {:id=>vertical_datum.id}.as_json, :callback=>params[:jsoncallback]
          }
        end
      end
    }
  end
  
  #HISTORY!
  def versions
    ### LOCAL VERTICAL DATUM HISTORY
    @global = false
    @project = parent
    #@project.managed_repository{
      #@cv_item = Voeis::VerticalDatumCV.get(params[:id])
      #@cv_versions = @cv_item.versions
      @cv_item = @project.managed_repository{Voeis::VerticalDatumCV.get(params[:id])}
      #@cv_versions = @project.managed_repository{Voeis::VerticalDatumCV.get(params[:id]).versions}
      @cv_versions = @project.managed_repository.adapter.select('SELECT * FROM voeis_vertical_datum_cv_versions WHERE id=%s ORDER BY updated_at DESC'%@cv_item.id)
      #@cv_versions = @project.managed_repository{@cv_item.versions_array}
      @cv_title = 'Vertical Datum'
      @cv_title2 = 'vertical_datum'
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
    #}
    #render 'spatial_references/versions.html.haml'
    render 'voeis/cv_versions.html.haml'
  end

  def invalid_page
    redirect_to(:back)
  end
end