require 'responders/rql'

class QualityControlLevelsController  < InheritedResources::Base
  rescue_from ActionView::MissingTemplate, :with => :invalid_page
  responders :rql
  defaults  :route_collection_name => 'quality_control_levels',
            :route_instance_name => 'quality_control_level',
            :collection_name => 'quality_control_levels',
            :instance_name => 'quality_control_level',
            :resource_class => Voeis::QualityControlLevel

  has_widgets do |root|
    root << widget(:versions)
    root << widget(:edit_cv)
  end

  ### GET /quality_control_level/new
  def new
    @quality_control_level = Voeis::QualityControlLevel.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  ### GLOBAL: POST /quality_control_level
  def create
    cvparams = params
    cvparams = params[:quality_control_level] if !params[:quality_control_level].nil?
    @quality_control_level = Voeis::QualityControlLevel.new(
                            :quality_control_level_code=>cvparams[:quality_control_level_code],
                            :definition=>cvparams[:definition],
                            :explanation=>cvparams[:explanation])
    respond_to do |format|
      if @quality_control_level.save
        format.json do
          render :json => @quality_control_level.as_json, :callback => params[:jsoncallback]
        end
        format.html do
          flash[:notice] = 'Quality Control Level was successfully created.'
          redirect_to(new_quality_control_level_path())
        end
      else
        format.html { render :action => "new" }
      end
    end
  end
  
  ### GLOBAL: PUT /quality_control_level
  def update
    cvparams = params
    cvparams = params[:quality_control_level] if !params[:quality_control_level].nil?
    @quality_control_level = Voeis::QualityControlLevel.get(cvparams[:id].to_i)
    cvparams.each do |key, value|
      @quality_control_level[key] = value.blank? ? nil : value
    end
    @quality_control_level.updated_at = Time.now
    
    respond_to do |format|
      if @quality_control_level.save
        format.json do
          render :json => @quality_control_level.as_json, :callback => params[:jsoncallback]
        end
        format.html do
          flash[:notice] = 'Quality Control Level was successfully updated.'
          redirect_to(new_quality_control_level_path())
        end
      else
        format.html { render :action => "new" }
      end
    end
  end

  ### GLOBAL: DELETE /quality_control_level
  def destroy
    quality_control_level = Voeis::VariableNameCV.get(params[:id])
    #debugger
    if !quality_control_level.destroy
      #FAILED!
      #format.html { render :action => "update" }
      error_notice = 'Quality Control Level delete FAILED!'
      respond_to do |format|
        format.html {
          flash[:error] = error_notice
          redirect_to(quality_control_level_path())
        }
        format.json {
          render :json=>{:id=>quality_control_level.id,:errors=>[error_notice]}.as_json, :callback=>params[:jsoncallback]
        }
      end
    else
      respond_to do |format|
        format.html {
          flash[:notice] = 'Quality Control Level was successfully deleted.'
          redirect_to(quality_control_level_path())
        }
        format.json {
          render :json => {:id=>quality_control_level.id}.as_json, :callback=>params[:jsoncallback]
        }
      end
    end
  end
  
  def show
  end

  ### GLOBAL: GET /quality_control_level -- QualityControlLevel entries
  def index
    if User.current.nil? || User.current.system_role.name!='Administrator'
      flash[:notice] = 'You have inadequate permissions for this operation.'
      redirect_to :back
    end
    ### GLOBAL QUALITY CONTROL LEVEL
    @global = true
    @cv_data0 = Voeis::QualityControlLevel.all
    @cv_data = @cv_data0.map{|d| d.attributes.update({:used=>false})}
    @cv_title = 'Quality Control Level'
    @cv_title2 = 'global_quality_control_level'
    @cv_title2cv = 'quality_control_level'
    @cv_id = 'id'
    @cv_name = 'quality_control_level_code'
    @cv_columns = [{:field=>"id", :label=>"ID", :width=>"25px", :filterable=>false, :formatter=>"", :style=>""},
                  {:field=>"quality_control_level_code", :label=>"Quality Control Level", :width=>"200px", :filterable=>true, :formatter=>"", :style=>""},
                  {:field=>"definition", :label=>"Definition", :width=>"", :filterable=>true, :formatter=>"", :style=>""},
                  {:field=>"explanation", :label=>"Explanation", :width=>"", :filterable=>true, :formatter=>"", :style=>""},
                  {:field=>"updated_at", :label=>"Updated", :width=>"80px", :filterable=>true, :formatter=>"dateTime", :style=>""}]
    @cv_form = [{:field=>"id", :type=>"-IH", :required=>"", :style=>""},
                  {:field=>"idx", :type=>"-XH", :required=>"", :style=>""},
                  {:field=>"Quality Control Level", :type=>"-LL", :required=>"", :style=>""},
                  {:field=>"quality_control_level_code", :type=>"1B-SNB", :required=>"true", :style=>""},
                  {:field=>"Definition", :type=>"2B-LL", :required=>"false", :style=>""},
                  {:field=>"definition", :type=>"1B-STA", :required=>"false", :style=>""},
                  {:field=>"Explanation", :type=>"2B-LL", :required=>"false", :style=>""},
                  {:field=>"explanation", :type=>"1B-STA", :required=>"false", :style=>""}]
    render 'voeis/cv_index.html.haml'
  end

  ### GLOBAL: QUALITY CONTROL HISTORY!
  def versions
    @global = true
    @cv_item = Voeis::QualityControlLevel.get(params[:id])
    @cv_versions = @cv_item.versions.to_a
    @cv_title = 'Quality Control Level'
    @cv_title2 = 'global_quality_control_level'
    @cv_name = 'quality_control_level_code'
    @cv_term = 'quality_control_level_code'
    @cv_id = 'id'

    @cv_refs = []

    @cv_properties = [
#      {:label=>"Version", :name=>"version"},
#      {:label=>"ID", :name=>"id"},
      {:label=>"Quality Control Level", :name=>"quality_control_level_code"},
      {:label=>"Definition", :name=>"definition"},
      {:label=>"Explanation", :name=>"explanation"}
      ]

    render 'spatial_references/versions.html.haml'
  end

  def invalid_page
    redirect_to(:back)
  end
end