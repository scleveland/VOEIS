class Voeis::VariablesController < Voeis::BaseController
  
  # Properly override defaults to ensure proper controller behavior
  # @see Voeis::BaseController
  defaults  :route_collection_name => 'variables',
            :route_instance_name => 'variable',
            :collection_name => 'variables',
            :instance_name => 'variable',
            :resource_class => Voeis::Variable

  has_widgets do |root|
    root << widget(:flot_graph)
  end

  def show
    @project = parent
    #@sites = Voeis::Site.all
    @auth = !current_user.nil? && current_user.projects.include?(@project)
    @var_id = params[:id].to_i
    @variablexx = {
      :id=>0,
      :variable_name=>'',
      :variable_code=>'',
      :sample_medium=>'Unknown',
      :variable_untis_id=>0,
      :general_category=>'Unknown',
      :value_type=>'Unknown',
      :speciation=>'Not Applicable',
      :data_type=>'Unknown',
      :quality_control=>0,
      :time_support=>1.0,
      :is_regular=>false,
      :time_units_id=>103,
      :lab_id=>nil,
      :lab_method_id=>nil,
      :field_method_id=>nil,
      :spatial_offset_type=>'',
      :spatial_offset_value=>nil,
      :spatial_units_id=>nil,
      :no_data_value=>'-9999',
      :detection_limit=>nil,
      :logger_type=>'',
      :logger_id=>'',
      :sensor_type=>'',
      :sensor_id=>'',
      :his_id=>nil,
      :updated_at=>'',
      :updated_by=>'',
      :updated_comment=>'',
      :provenance_comment=>'',
      :created_at=>''
    }
    @variable = Voeis::Variable.new
    @variable.id = 0
    @variable_ref = {}
    if @var_id>0
      @project.managed_repository{
        @variable = Voeis::Variable.get(@var_id)
        @sites = Voeis::Site.all
        if !params[:site_id].nil?
          @site =  Voeis::Site.get(params[:site_id].to_i)
          @site_variable_stats = Voeis::SiteDataCatalog.all(:variable_id=>params[:id].to_i, :site_id=>params[:site_id].to_i)
          @graph_data = @variable.last_ten_values_graph(@site)
          @data = @variable.last_ten_values(@site)
        end
      }
      @variable_ref = {}
      Voeis::Variable.properties.each{|prop| @variable_ref[prop.name] = @variable[prop.name]}
      #@units = Voeis::Unit.get(@variable.variable_units_id)
      #@tunits = Voeis::Unit.get(@variable.time_units_id)
      @units = @variable.variable_units
      sunits = @variable.spatial_units
      @variable_ref[:variable_units] = '%s (%s)'%[@units[:units_abbreviation],@units[:units_type]]
      @variable_ref[:time_units] = @variable.time_units[:units_name]
      @variable_ref[:lab_method] = @variable.lab_method.nil? ? 'NA' : @variable.lab_method.lab_method_name
      @variable_ref[:lab] = @variable.lab.nil? ? 'NA' : '%s (%s)'%[@variable.lab.lab_name,@variable.lab.lab_organization]
      @variable_ref[:field_method] = @variable.field_method.nil? ? 'NA' : @variable.field_method.method_name
      @variable_ref[:spatial_units] = sunits.nil? ? 'NA' : '%s (%s)'%[sunits[:units_abbreviation],sunits[:units_type]]
    end
    @variable_properties = [
      {:label=>"Variable ID", :name=>"id"},
      {:label=>"Name", :name=>"variable_name"},
      {:label=>"Code", :name=>"variable_code"},
      {:label=>"Sample Medium", :name=>"sample_medium"},
      {:label=>"Units", :name=>"variable_units"},
      {:label=>"General Category", :name=>"general_category"},
      {:label=>"Value Type", :name=>"value_type"},
      {:label=>"Speciation", :name=>"speciation"},
      {:label=>"Data Type", :name=>"data_type"},
      {:label=>"Quality Control", :name=>"quality_control"},
      {:label=>"Time Support", :name=>"time_support"},
      {:label=>"Regular Interval", :name=>"is_regular"},
      {:label=>"Time Units", :name=>"time_units"},
      {:label=>"Laboratory", :name=>"lab"},
      {:label=>"Lab Method", :name=>"lab_method"},
      {:label=>"Field Method", :name=>"field_method"},
      {:label=>"Spatial Offset Type", :name=>"spatial_offset_type"},
      {:label=>"Spatial Offset Value", :name=>"spatial_offset_value"},
      {:label=>"Spatial Units", :name=>"spatial_units"},
      {:label=>"Null Value", :name=>"no_data_value"},
      {:label=>"Detection Limit", :name=>"detection_limit"},
      {:label=>"Logger Type", :name=>"logger_type"},
      {:label=>"Logger ID", :name=>"logger_id"},
      {:label=>"Sensor Type", :name=>"sensor_type"},
      {:label=>"Sensor ID", :name=>"sensor_id"},
      {:label=>"HIS ID", :name=>"his_id"},
      {:label=>"Updated", :name=>"updated_at"},
      {:label=>"Updated By", :name=>"updated_by"},
      {:label=>"Update Comment", :name=>"updated_comment"},
      {:label=>"Provenance Comment", :name=>"provenance_comment"},
      {:label=>"Created", :name=>"created_at"}
      ]
    
    @units_all = Voeis::Unit.all(:order=>"units_type")
    @laboratories = Voeis::Lab.all
    @lab_methods = Voeis::LabMethod.all
    @field_methods = Voeis::FieldMethod.all
    
    #logger.debug('>>>> graph_data = '+@graph_data.to_s)
    #logger.debug('>>>> data = '+@data.to_s)
    #@versions = parent.managed_repository{Voeis::Site.get(params[:id]).versions}
    
  end

  # GET /variables/new
  def new
    @variables = Voeis::Variable.all
    @variable = Voeis::Variable.new
    @units = Voeis::Unit.all
    @time_units = Voeis::Unit.all(:units_type.like=>'%Time%')
    @variable_names = Voeis::VariableNameCV.all
    @sample_mediums= Voeis::SampleMediumCV.all
    @value_types= Voeis::ValueTypeCV.all
    @speciations = Voeis::SpeciationCV.all
    @data_types = Voeis::DataTypeCV.all
    @general_categories = Voeis::GeneralCategoryCV.all
    @label_array = Array["Variable Name","Variable Code","Unit Name","Speciation","Sample Medium","Value Type","Is Regular","Time Support","Time Unit ID","Data Type","General Cateogry", "Detection Limit"]

    @current_variables = Array.new     
    @variables.all(:order => [:variable_name.asc]).each do |var|
      @temp_array =Array[var.variable_name, var.variable_code,@units.get(var.variable_units_id).units_name, var.speciation,var.sample_medium, var.value_type, var.is_regular.to_s, var.time_support.to_s, var.time_units_id.to_s, var.data_type, var.general_category, var.detection_limit.to_s]
      @current_variables << @temp_array
    end         
    @project = parent
    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  # POST /variables
  def create

    @variable = Voeis::Variable.new(params[:variable])
    if @variable.variable_code.nil? || @variable_code =="undefined"
      @variable.variable_code = @variable.id.to_s+@variable.variable_name+@variable.speciation+Voeis::Unit.get(@variable.variable_units_id).units_name
    end
    if params[:variable][:detection_limit].empty?
      @variable.detection_limit = nil
    end
    if params[:variable][:field_method_id].empty?
      @variable.field_method_id = nil
    end
    if params[:variable][:lab_id].empty?
      @variable.lab_id = nil
    end
    if params[:variable][:lab_method_id].empty?
      @variable.lab_method_id = nil
    end
    if params[:variable][:spatial_offset_type].empty?
      @variable.spatial_offset_type = nil
    end
    @variable.valid?
    puts @variable.errors.inspect()
    if @variable.save  
      respond_to do |format|
        flash[:notice] = 'Variable was successfully created.'
        redirect_to(new_project_variable_path(parent))
        format.json do
           render :json => @variable.as_json, :callback => params[:jsoncallback]
        end
        return
      end
    else
      respond_to do |format|
        flash[:warning] = 'There was a problem saving the Variables.'
        format.html { render :action => "new" }
        format.json do
           render :json => @variable.as_json, :callback => params[:jsoncallback]
        end
        return
      end
    end
  end
end
