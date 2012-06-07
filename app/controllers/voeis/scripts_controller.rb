class Voeis::ScriptsController < Voeis::BaseController
  rescue_from ActionView::MissingTemplate, :with => :invalid_page

  has_widgets do |root|
    root << widget(:versions)
  end


  # GET /script/new
  def new
    @script = parent.managed_repository{Voeis::Script.new}

    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  # GET /script/list
  def list
    @project = parent
    @variables = @project.managed_repository{ Voeis::Script.all }
    respond_to do |format|
      format.html # new.html.erb
    end
    respond_to do |format|
      format.json do
        render :json => @scripts.as_json, :callback => params[:jsoncallback]
      end
    end
  end
  
  # POST /script
  def create
    @project = parent
    @project.managed_repository{
      if params[:script][:id].nil?
        @script = Voeis::Script.create(params[:script])
      else
        @script = Voeis::Script.with_deleted{Voeis::Script.get(params[:script][:id])}
        if @script.nil?
          @script = Voeis::Script.create(params[:script])
        else
          #RESTORE DELETED
          #@script.deleted_at  #need to reference 'deleted_at' because of lazy loading
          @script.update(params[:script].update(:deleted_at=>nil))
        end
      end
    
      respond_to do |format|
        format.html do
          flash[:notice] = 'Script was successfully created.'
          redirect_to(script_path())
        end
        format.json do
          render :json => @script.as_json, :callback => params[:jsoncallback]
        end
      end
    }
  end
  
  # PUT /script
  def update
    @project = parent
    @project.managed_repository{
      script = Voeis::Script.get(params[:id].to_i)
    
      #params[:script].each do |key, value|
      #  #script[key] = value.blank? ? nil : value
      #  script[key] = value
      #end
      script_saved = script.update(params[:script].update(:updated_at=>Time.now))
      #debugger
      
      respond_to do |format|
        if script_saved
          format.html do
            flash[:notice] = 'Script was successfully updated.'
            #redirect_to(script_path())
            render :action => "update"
          end
          format.json do
            render :json => script.as_json, :callback => params[:jsoncallback]
          end
        else
          format.html do
            flash[:error] = 'Script update FAILED!'
            redirect_to(project_path(@project))
          end
        end
      end
    }
  end

  # GET /script
  def show
    @project = parent
    @project.managed_repository{
      script = Voeis::Script.get(params[:id])
    
      respond_to do |format|
        format.html do
          #redirect_to(script_path())
          render :action => "show"
        end
        format.json do
          render :json => script.as_json, :callback => params[:jsoncallback]
        end
      end
    }
  end

  # DELETE /script
  def destroy
    @project = parent
    @project.managed_repository{
      script = Voeis::Script.get(params[:id])
      #debugger
      if !script.destroy
        #FAILED!
        #format.html { render :action => "update" }
        error_notice = 'Script delete FAILED!'
        respond_to do |format|
          format.html {
            flash[:error] = error_notice
            redirect_to(script_path())
          }
          format.json {
            render :json=>{:id=>vertical_datum.id,:errors=>[error_notice]}.as_json, :callback=>params[:jsoncallback]
          }
        end
      else
        respond_to do |format|
          format.html {
            flash[:notice] = 'Script was successfully deleted.'
            redirect_to(script_path())
          }
          format.json {
            render :json => {:id=>script.id}.as_json, :callback=>params[:jsoncallback]
          }
        end
      end
    }
  end
  

  # List Script entries -- GET /script
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
                    {:field=>"updated_at", :label=>"Updated", :width=>"80px", :filterable=>true, :formatter=>"dateTime", :style=>""}]
      @copy_columns = [{:field=>"id", :label=>"ID", :width=>"5%", :filterable=>false, :formatter=>"", :style=>""},
                    {:field=>"term", :label=>"Term", :width=>"15%", :filterable=>true, :formatter=>"", :style=>""},
                    {:field=>"definition", :label=>"Definition", :width=>"", :filterable=>true, :formatter=>"", :style=>""},
                    {:field=>"updated_at", :label=>"Updated", :width=>"18%", :filterable=>true, :formatter=>"dateTime", :style=>""}]
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

  # HISTORY!
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