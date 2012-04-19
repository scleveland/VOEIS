class DataTypeCVsController < ApplicationController
  rescue_from ActionView::MissingTemplate, :with => :invalid_page

  has_widgets do |root|
    root << widget(:versions)
    root << widget(:edit_cv)
  end


  ### GLOBAL: GET /data_type_c_vs/new
  def new
    @data_type = Voeis::DataTypeCV.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  ### GLOBAL: POST /data_type_c_vs
  def create
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
  end
  
  ### GLOBAL: PUT /data_type_c_vs
  def update
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
  end
  
  ### GLOBAL: DELETE /data_type_c_vs
  def destroy
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
  end
  
  def show
  end

  ### GLOBAL: GET /data_type_c_vs
  def index
    if User.current.nil? || User.current.system_role.name!='Administrator'
      flash[:notice] = 'You have inadequate permissions for this operation.'
      redirect_to(project_path(@project))
    end
    ### GLOBAL DataType
    @global = true
    @cv_data0 = Voeis::DataTypeCV.all
    @cv_data = @cv_data0.map{|d| d.attributes.update({:used=>false})}
    @cv_title = 'Data Type'
    @cv_title2 = 'global_data_type'
    @cv_title2cv = 'data_type_c_v'
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

  ### GLOBAL: DataType HISTORY!
  def versions
    @global = true
    @cv_item = Voeis::DataTypeCV.get(params[:id])
    @cv_versions = @cv_item.versions.to_a
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