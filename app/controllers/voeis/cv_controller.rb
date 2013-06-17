class Voeis::CVController < Voeis::BaseController
  rescue_from ActionView::MissingTemplate, :with => :invalid_page

  has_widgets do |root|
    root << widget(:versions)
    root << widget(:edit_cv)
  end

  @cv_type = nil
  @cv_class = nil
  @cv_global = nil
  @global = nil

  # getting: @cv_class, @cv_type, @cv_global
  
  ## CONFIG MAP for all CV types
  ## FORM INPUT TYPES from controller: :cv_form
  ## CV_FORM[:type] ("2B-XTA")
  ##      type 2B = preceed with 2x breaks (<br />)
  ##      2B preceed with 2x <br />
  ##      3S preceed with 3x &nbsp;
  ##      -
  ##      type: XTA = X:model type (not in model) -- TA:widget (Textarea)
  ##      model type: X:non-model -- I:integer -- N:number -- F:float -- S:string -- B:boolean -- L:label
  ##      widget type: H:hidden -- TB:TextBox -- NB:NumberBox -- DB:DateBox -- CK:CheckBox -- L:label
  ##                   TA:SimpleTextArea -- TA1:TextArea -- TA2:dijit_ext.ValidatonTextarea
  CV_MAP_BASE = {
    #:cv_columns => [{:field=>"id", :label=>"ID", :width=>"25px", :filterable=>false, :formatter=>"", :style=>""},
    :cv_columns => [{:field=>"term", :label=>"Term", :width=>"180px", :filterable=>true, :formatter=>"", :style=>""},
                  {:field=>"definition", :label=>"Definition", :width=>"", :filterable=>true, :formatter=>"", :style=>""},
                  {:field=>"used", :label=>"USED", :width=>"30px", :filterable=>true, :formatter=>"trueFalse", :style=>""}],
    #              {:field=>"updated_at", :label=>"Updated", :width=>"130px", :filterable=>true, :formatter=>"dateTime", :style=>""}],
    #:copy_columns => [{:field=>"id", :label=>"ID", :width=>"5%", :filterable=>false, :formatter=>"", :style=>""},
    :copy_columns => [{:field=>"term", :label=>"Term", :width=>"15%", :filterable=>true, :formatter=>"", :style=>""},
                  {:field=>"definition", :label=>"Definition", :width=>"", :filterable=>true, :formatter=>"", :style=>""}],
    #              {:field=>"updated_at", :label=>"Updated", :width=>"130px", :filterable=>true, :formatter=>"dateTime", :style=>""}],
    :cv_form => [{:field=>"id", :type=>"-IH", :required=>"", :style=>""},
                  {:field=>"idx", :type=>"-XH", :required=>"", :style=>""},
                  {:field=>"Term", :type=>"-LL", :required=>"", :style=>""},
                  {:field=>"term", :type=>"1B-STB", :required=>"true", :style=>""},
                  {:field=>"Definition", :type=>"2B-LL", :required=>"false", :style=>""},
                  {:field=>"definition", :type=>"1B-STA", :required=>"false", :style=>""}],
    :cv_properties => [
                  #{:label=>"Version", :name=>"version"},
                  #{:label=>"ID", :name=>"id"},
                  {:label=>"Term", :name=>"term"},
                  {:label=>"Definition", :name=>"definition"}],
    ###???EXPERIMENTAL???
    :cv_list_refs => lambda {|item,parent|
      ### define :used
      {:used=>(!parent.variables.first(:data_type=>item.term).nil?)}
    }
  }
  CV_MAP = {
    :data_type => {
      :cv_title => "Data Type",
      :cv_title2 => "data_type",
      :cv_title2cv => "data_type_c_v",
      :cv_table => "data_type_cv",
      :cv_id => "id",
      :cv_name => "term",
      :cv_columns => CV_MAP_BASE[:cv_columns],
      :copy_columns => CV_MAP_BASE[:copy_columns],
      :cv_form => CV_MAP_BASE[:cv_form],
      :cv_properties => CV_MAP_BASE[:cv_properties],
      :cv_list_refs => lambda {|item,parent|
        ### define :used
        {:used=>(!parent.variables.first(:data_type=>item.term).nil?)}
      }
    },
    :general_category => {
      :cv_title => "General Category",
      :cv_title2 => "general_category",
      :cv_title2cv => "general_category_c_v",
      :cv_id => "id",
      :cv_name => "term",
      :cv_columns => CV_MAP_BASE[:cv_columns],
      :copy_columns => CV_MAP_BASE[:copy_columns],
      :cv_form => CV_MAP_BASE[:cv_form],
      :cv_properties => CV_MAP_BASE[:cv_properties],
      :cv_list_refs => lambda {|item,parent|
        ### define :used
        {:used=>(!parent.variables.first(:general_category=>item.term).nil?)}
      }
    },
    :quality_control_level => {
      :cv_title => 'Quality Control Level',
      :cv_title2 => 'quality_control_level',
      :cv_title2cv => 'quality_control_level',
      :cv_id => 'id',
      :cv_name => 'quality_control_level_code',
      :cv_columns => [{:field=>"quality_control_level_code", :label=>"Quality Control Level", :width=>"150px", :filterable=>true, :formatter=>"", :style=>""},
                    {:field=>"definition", :label=>"Definition", :width=>"", :filterable=>true, :formatter=>"", :style=>""},
                    {:field=>"explanation", :label=>"Explanation", :width=>"", :filterable=>true, :formatter=>"", :style=>""},
                    {:field=>"used", :label=>"USED", :width=>"30px", :filterable=>true, :formatter=>"trueFalse", :style=>""}],
      :copy_columns => [{:field=>"quality_control_level_code", :label=>"Quality Control Level", :width=>"150px", :filterable=>true, :formatter=>"", :style=>""},
                    {:field=>"definition", :label=>"Definition", :width=>"", :filterable=>true, :formatter=>"", :style=>""},
                    {:field=>"explanation", :label=>"Explanation", :width=>"", :filterable=>true, :formatter=>"", :style=>""}],
      :cv_form => [{:field=>"id", :type=>"-IH", :required=>"", :style=>""},
                    {:field=>"idx", :type=>"-XH", :required=>"", :style=>""},
                    {:field=>"Quality Control Level", :type=>"-LL", :required=>"", :style=>""},
                    {:field=>"quality_control_level_code", :type=>"1B-SNB", :required=>"true", :style=>""},
                    {:field=>"Definition", :type=>"2B-LL", :required=>"false", :style=>""},
                    {:field=>"definition", :type=>"1B-STA", :required=>"false", :style=>""},
                    {:field=>"Explanation", :type=>"2B-LL", :required=>"false", :style=>""},
                    {:field=>"explanation", :type=>"1B-STA", :required=>"false", :style=>""}],
      :cv_properties => [
                    #{:label=>"Version", :name=>"version"},
                    #{:label=>"ID", :name=>"id"},
                    {:label=>"Quality Control Code", :name=>"quality_control_level_code"},
                    {:label=>"Definition", :name=>"definition"},
                    {:label=>"Explanation", :name=>"explanation"}],
      :cv_paramsxx => {
                    :quality_control_level_code => lambda {|value| value.to_i }},
      :cv_list_refsxx => lambda {|item,parent|
        ### define :used
        {:used=>(!parent.managed_repository{ Voeis::DataValue.first(:quality_control_level=>item.quality_control_level_code).nil? })}
      }
    },
    :sample_medium => {
      :cv_title => 'Sample Medium',
      :cv_title2 => 'sample_medium',
      :cv_title2cv => 'sample_medium_c_v',
      :cv_id => 'id',
      :cv_name => 'term',
      :cv_columns => CV_MAP_BASE[:cv_columns],
      :copy_columns => CV_MAP_BASE[:copy_columns],
      :cv_form => CV_MAP_BASE[:cv_form],
      :cv_properties => CV_MAP_BASE[:cv_properties],
      :cv_list_refs => lambda {|item,parent|
        ### define :used
        {:used=>(!parent.variables.first(:sample_medium=>item.term).nil?)}
      }
    },
    :sample_type => {
      :cv_title => 'Sample Type',
      :cv_title2 => 'sample_type',
      :cv_title2cv => 'sample_type_c_v',
      :cv_id => 'id',
      :cv_name => 'term',
      :cv_columns => CV_MAP_BASE[:cv_columns],
      :copy_columns => CV_MAP_BASE[:copy_columns],
      :cv_form => CV_MAP_BASE[:cv_form],
      :cv_properties => CV_MAP_BASE[:cv_properties],
      :cv_list_refsxx => lambda {|item,parent|
        ### define :used
        {:used=>(!parent.variables.first(:sample_type=>item.term).nil?)}
      }
    },
    :spatial_reference => {
      :cv_title => "Spatial Reference",
      :cv_title2 => 'spatial_reference',
      :cv_title2cv => 'spatial_reference',
      :cv_table => "spatial_reference",
      :cv_id => 'id',
      :cv_name => 'srs_name',
      :cv_columns => [{:field=>"srs_name", :label=>"Source Name", :width=>"110px", :filterable=>true, :formatter=>"", :style=>""},
                    {:field=>"srs_id", :label=>"Source ID", :width=>"80px", :filterable=>true, :formatter=>"", :style=>""},
                    {:field=>"is_geographic", :label=>"GEO", :width=>"30px", :filterable=>true, :formatter=>"trueFalse", :style=>""},
                    {:field=>"notes", :label=>"Notes", :width=>"", :filterable=>true, :formatter=>"", :style=>""},
                    {:field=>"used", :label=>"USED", :width=>"30px", :filterable=>true, :formatter=>"trueFalse", :style=>""}],
      :copy_columns => [{:field=>"srs_name", :label=>"Source Name", :width=>"110px", :filterable=>true, :formatter=>"", :style=>""},
                    {:field=>"srs_id", :label=>"Source ID", :width=>"80px", :filterable=>true, :formatter=>"", :style=>""},
                    {:field=>"is_geographic", :label=>"GEO", :width=>"30px", :filterable=>true, :formatter=>"trueFalse", :style=>""},
                    {:field=>"notes", :label=>"Notes", :width=>"", :filterable=>true, :formatter=>"", :style=>""}],
      :cv_form => [{:field=>"id", :type=>"-IH", :required=>"", :style=>""},
                    {:field=>"idx", :type=>"-XH", :required=>"", :style=>""},
                    {:field=>"Source Name", :type=>"-LL", :required=>"", :style=>""},
                    {:field=>"srs_name", :type=>"1B-STB", :required=>"true", :style=>""},
                    {:field=>"Source ID", :type=>"2B-LL", :required=>"", :style=>""},
                    {:field=>"srs_id", :type=>"1B-INB", :required=>"true", :style=>""},
                    {:field=>"is_geographic", :type=>"6S-BCK", :required=>"false", :style=>""},
                    {:field=>"Geographic", :type=>"1S-LL", :required=>"", :style=>""},
                    {:field=>"Notes", :type=>"2B-LL", :required=>"", :style=>""},
                    {:field=>"notes", :type=>"1B-STA", :required=>"false", :style=>""}],
      :cv_properties => [
                    #{:label=>"Version", :name=>"version"},
                    #{:label=>"ID", :name=>"id"},
                    {:label=>"Source Name", :name=>"srs_name"},
                    {:label=>"Source ID", :name=>"srs_id"},
                    {:label=>"Geographic", :name=>"is_geo_string", :contains=>["is_geographic"]},
                    {:label=>"Notes", :name=>"notes"}],
      :cv_params => {
        :srs_id => lambda {|value| value.to_i },
        :is_geographic => lambda {|value| value=~(/(true|t|yes|y|1)/i) ? true : false }},
      :cv_ver_refs => lambda {|item,versions|
        cv_refs = []
        temp = {}
        temp[:is_geo_string] = item.is_geographic ? 'True' : 'False'
        cv_refs << temp
        versions.each{|ver| 
          temp = {}
          temp[:is_geo_string] = ver.is_geographic ? 'True' : 'False'
          cv_refs << temp
        }
        cv_refs
      },
      :cv_list_refs => lambda {|item,parent|
        ### define :used
        {:used=>(!parent.sites.first(:lat_long_datum_id=>item.id).nil? || 
          !parent.sites.first(:local_projection_id=>item.id).nil?)}
      }
    },
    :speciation => {
      :cv_title => 'Speciation',
      :cv_title2 => 'speciation',
      :cv_title2cv => 'speciation_c_v',
      :cv_id => 'id',
      :cv_name => 'term',
      :cv_columns => CV_MAP_BASE[:cv_columns],
      :copy_columns => CV_MAP_BASE[:copy_columns],
      :cv_form => CV_MAP_BASE[:cv_form],
      :cv_properties => CV_MAP_BASE[:cv_properties],
      :cv_list_refs => lambda {|item,parent|
        ### define :used
        {:used=>(!parent.variables.first(:speciation=>item.term).nil?)}
      }
    },
    :variable_name => {
      :cv_title => "Variable Name",
      :cv_title2 => "variable_name",
      :cv_title2cv => "variable_name_c_v",
      :cv_table => "variable_name_cv",
      :cv_id => "id",
      :cv_name => "term",
      :cv_columns => CV_MAP_BASE[:cv_columns],
      :copy_columns => CV_MAP_BASE[:copy_columns],
      :cv_form => CV_MAP_BASE[:cv_form],
      :cv_properties => CV_MAP_BASE[:cv_properties],
      :cv_list_refs => lambda {|item,parent|
        ### define :used
        {:used=>(!parent.variables.first(:variable_name=>item.term).nil?)}
      }
    },
    :value_type => {
      :cv_title => 'Value Type',
      :cv_title2 => 'value_type',
      :cv_title2cv => 'value_type_c_v',
      :cv_id => 'id',
      :cv_name => 'term',
      :cv_columns => CV_MAP_BASE[:cv_columns],
      :copy_columns => CV_MAP_BASE[:copy_columns],
      :cv_form => CV_MAP_BASE[:cv_form],
      :cv_properties => CV_MAP_BASE[:cv_properties],
      :cv_list_refs => lambda {|item,parent|
        ### define :used
        {:used=>(!parent.variables.first(:value_type=>item.term).nil?)}
      }
    },
    :vertical_datum => {
      :cv_title => 'Vertical Datum',
      :cv_title2 => 'vertical_datum',
      :cv_title2cv => 'vertical_datum_c_v',
      :cv_id => 'id',
      :cv_name => 'term',
      :cv_columns => CV_MAP_BASE[:cv_columns],
      :copy_columns => CV_MAP_BASE[:copy_columns],
      :cv_form => CV_MAP_BASE[:cv_form],
      :cv_properties => CV_MAP_BASE[:cv_properties],
      :cv_list_refs => lambda {|item,parent|
        ### define :used
        {:used=>(!parent.sites.first(:vertical_datum_id=>item.id).nil?)}
      }
    },
    :sensor_type => {
      :cv_title => 'Sensor Type',
      :cv_title2 => 'sensor_type',
      :cv_title2cv => 'sensor_type_c_v',
      :cv_id => 'id',
      :cv_name => 'term',
      :cv_columns => [{:field=>"term", :label=>"Term", :width=>"180px", :filterable=>true, :formatter=>"", :style=>""},
                    {:field=>"description", :label=>"Description", :width=>"", :filterable=>true, :formatter=>"", :style=>""}],
      #:copy_columns => [{:field=>"id", :label=>"ID", :width=>"5%", :filterable=>false, :formatter=>"", :style=>""},
      :copy_columns => [{:field=>"term", :label=>"Term", :width=>"180px", :filterable=>true, :formatter=>"", :style=>""},
                    {:field=>"description", :label=>"Description", :width=>"", :filterable=>true, :formatter=>"", :style=>""}],
      :cv_form => [{:field=>"id", :type=>"-IH", :required=>"", :style=>""},
                    {:field=>"idx", :type=>"-XH", :required=>"", :style=>""},
                    {:field=>"Term", :type=>"-LL", :required=>"", :style=>""},
                    {:field=>"term", :type=>"1B-STB", :required=>"true", :style=>""},
                    {:field=>"Description", :type=>"2B-LL", :required=>"false", :style=>""},
                    {:field=>"description", :type=>"1B-STA", :required=>"false", :style=>""}],
      :cv_properties => [
                    #{:label=>"Version", :name=>"version"},
                    #{:label=>"ID", :name=>"id"},
                    {:label=>"Term", :name=>"term"},
                    {:label=>"Description", :name=>"description"}]
    },
    :logger_type => {
      :cv_title => 'Logger Type',
      :cv_title2 => 'logger_type',
      :cv_title2cv => 'logger_type_c_v',
      :cv_id => 'id',
      :cv_name => 'term',
      :cv_columns => [{:field=>"term", :label=>"Term", :width=>"180px", :filterable=>true, :formatter=>"", :style=>""},
                    {:field=>"description", :label=>"Description", :width=>"", :filterable=>true, :formatter=>"", :style=>""}],
      #:copy_columns => [{:field=>"id", :label=>"ID", :width=>"5%", :filterable=>false, :formatter=>"", :style=>""},
      :copy_columns => [{:field=>"term", :label=>"Term", :width=>"180px", :filterable=>true, :formatter=>"", :style=>""},
                    {:field=>"description", :label=>"Description", :width=>"", :filterable=>true, :formatter=>"", :style=>""}],
      :cv_form => [{:field=>"id", :type=>"-IH", :required=>"", :style=>""},
                    {:field=>"idx", :type=>"-XH", :required=>"", :style=>""},
                    {:field=>"Term", :type=>"-LL", :required=>"", :style=>""},
                    {:field=>"term", :type=>"1B-STB", :required=>"true", :style=>""},
                    {:field=>"Description", :type=>"2B-LL", :required=>"false", :style=>""},
                    {:field=>"description", :type=>"1B-STA", :required=>"false", :style=>""}],
      :cv_properties => [
                    #{:label=>"Version", :name=>"version"},
                    #{:label=>"ID", :name=>"id"},
                    {:label=>"Term", :name=>"term"},
                    {:label=>"Description", :name=>"description"}]
    }
  }


  ### INITIALIZE CLASS VARS
  def init(cvtype,cvclass,cvglobal)
    @cv_type = cvtype
    @cv_class = cvclass
    @cv_global = cvglobal
    @global = @cv_global
  end
  
  ### GET /cv_title2/new
  def new
    @data_type = @cv_class.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  ### POST /cv_title2
  def create
    props = CV_MAP[@cv_type][:cv_properties].map{|x| x[:name].to_sym}
    cv_sym = CV_MAP[@cv_type][:cv_title2cv].to_sym
    if @cv_global
      cvparams = params[cv_sym]
      cvparams = Hash[props.map{|x| [x,params[x]]}] if cvparams.nil?
      if !CV_MAP[@cv_type][:cv_params].nil?
        CV_MAP[@cv_type][:cv_params].each{|key, filter| cvparams[key.to_s] = filter.call(cvparams[key.to_s]) if !filter.nil?}
      end
      @cv_item = @cv_class.new(cvparams)
      respond_to do |format|
        if @cv_item.save
          format.html do
            flash[:notice] = '#{CV_MAP[@cv_type][:cv_title]} was successfully created.'
            redirect_to("/#{CV_MAP[@cv_type][:cv_title2cv]}s/#{@cv_item.id}.html")
          end
          format.json do
            render :json => @cv_item.as_json, :callback => params[:jsoncallback]
          end
        else
          format.html { render :action => "new" }
        end
      end
    else
      @project = parent
      @project.managed_repository{
        cvparams = params[cv_sym]
        cvparams = Hash[props.map{|x| [x,params[x]]}] if cvparams.nil?
        if !CV_MAP[@cv_type][:cv_params].nil?
          CV_MAP[@cv_type][:cv_params].each{|key, filter| cvparams[key.to_s] = filter.call(cvparams[key.to_s]) if !filter.nil?}
        end
        @cv_item = @cv_class.new(cvparams)
        respond_to do |format|
          if @cv_item.save
            format.html do
              flash[:notice] = '#{CV_MAP[@cv_type][:cv_title]} was successfully created.'
              redirect_to(project_path(@project)+"/#{CV_MAP[@cv_type][:cv_title2cv]}s/#{@cv_item.id}.html")
            end
            format.json do
              render :json => @cv_item.as_json, :callback => params[:jsoncallback]
            end
          else
            format.html { render :action => "new" }
          end
        end
      }
    end
  end
  
  ### PUT /cv_title2
  def update
    props = CV_MAP[@cv_type][:cv_properties].map{|x| x[:name].to_sym}
    cv_sym = CV_MAP[@cv_type][:cv_title2cv].to_sym
    if @cv_global
      cvparams = params
      cvparams = params[cv_sym] if !params[cv_sym].nil?
      if !CV_MAP[@cv_type][:cv_params].nil?
        CV_MAP[@cv_type][:cv_params].each{|key, filter| cvparams[key.to_s] = filter.call(cvparams[key.to_s]) if !filter.nil?}
      end
      
      @cv_item = @cv_class.first(:id=>params[:id])
      cvparams.each do |key, value|
        @cv_item[key] = value.blank? ? nil : value
      end
      @cv_item.updated_at = Time.now
    
      respond_to do |format|
        if @cv_item.save
          format.html do
            flash[:notice] = '#{CV_MAP[@cv_type][:cv_title]} was successfully updated.'
            redirect_to("/#{CV_MAP[@cv_type][:cv_title2cv]}s/#{@cv_item.id}.html")
          end
          format.json do
            render :json => @cv_item.as_json, :callback => params[:jsoncallback]
          end
        else
          format.html { render :action => "new" }
        end
      end
    else
      @project = parent
      @project.managed_repository{
        cvparams = params
        cvparams = params[cv_sym] if !params[cv_sym].nil?
        if !CV_MAP[@cv_type][:cv_params].nil?
          CV_MAP[@cv_type][:cv_params].each{|key, filter| cvparams[key.to_s] = filter.call(cvparams[key.to_s]) if !filter.nil?}
        end
        logger.info '### UPDATE cvparams ###'
        logger.info cvparams.to_hash
        
        @cv_item = @cv_class.first(:id=>params[:id])
        cvparams.each do |key, value|
          @cv_item[key] = value.blank? ? nil : value
        end
        @cv_item.updated_at = Time.now
        
        logger.info '### UPDATE #{CV_MAP[@cv_type][:cv_title]} ###'
        logger.info @cv_item.to_hash
        
        respond_to do |format|
          if @cv_item.save
            format.html do
              flash[:notice] = '#{CV_MAP[@cv_type][:cv_title]} was successfully updated.'
              redirect_to(project_path(@project)+"/#{CV_MAP[@cv_type][:cv_title2cv]}s/#{@cv_item.id}.html")
            end
            format.json do
              render :json => @cv_item.as_json, :callback => params[:jsoncallback]
            end
          else
            format.html { render :action => "new" }
          end
        end
      }
    end
  end
  
  ### DELETE /cv_title2
  def destroy
    if @cv_global
      cv_item = @cv_class.get(params[:id])
      #debugger
      if !cv_item.destroy
        #FAILED!
        #format.html { render :action => "update" }
        error_notice = '#{CV_MAP[@cv_type][:cv_title]} delete FAILED!'
        respond_to do |format|
          format.html {
            flash[:error] = error_notice
            redirect_to("/#{CV_MAP[@cv_type][:cv_title2cv]}s.html")
          }
          format.json {
            render :json=>{:id=>cv_item.id,:errors=>[error_notice]}.as_json, :callback=>params[:jsoncallback]
          }
        end
      else
        respond_to do |format|
          format.html {
            flash[:notice] = '#{CV_MAP[@cv_type][:cv_title]} was successfully deleted.'
            redirect_to("/#{CV_MAP[@cv_type][:cv_title2cv]}s.html")
          }
          format.json {
            render :json => {:id=>cv_item.id}.as_json, :callback=>params[:jsoncallback]
          }
        end
      end
    else
      @project = parent
      @project.managed_repository{
        cv_item = @cv_class.get(params[:id])
        #debugger
        if !cv_item.destroy
          #FAILED!
          #format.html { render :action => "update" }
          error_notice = '#{CV_MAP[@cv_type][:cv_title]} delete FAILED!'
          respond_to do |format|
            format.html do
              flash[:error] = error_notice
              redirect_to(project_path(@project)+"/#{CV_MAP[@cv_type][:cv_title2cv]}s.html")
            end
            format.json {
              render :json=>{:id=>cv_item.id,:errors=>[error_notice]}.as_json, :callback=>params[:jsoncallback]
            }
          end
        else
          respond_to do |format|
            format.html {
              flash[:notice] = '#{CV_MAP[@cv_type][:cv_title]} was successfully deleted.'
              redirect_to(project_path(@project)+"/#{CV_MAP[@cv_type][:cv_title2cv]}s.html")
            }
            format.json {
              render :json => {:id=>cv_item.id}.as_json, :callback=>params[:jsoncallback]
            }
          end
        end
      }
    end
  end
  
  def show
  end

  ### LIST: GET /cv_title2/list
  def list
    @global = @cv_global
    @cv_title = CV_MAP[@cv_type][:cv_title]
    @cv_title2 = CV_MAP[@cv_type][:cv_title2]
    @cv_title2 = 'global_'+@cv_title2 if @global
    @cv_title2cv = CV_MAP[@cv_type][:cv_title2cv]
    @cv_id = CV_MAP[@cv_type][:cv_id]
    @cv_name = CV_MAP[@cv_type][:cv_name]
    @cv_columns = CV_MAP[@cv_type][:cv_columns]
    @cv_form = CV_MAP[@cv_type][:cv_form]
    if @cv_global
      if User.current.nil? || User.current.system_role.name!='Administrator'
        flash[:notice] = 'You have inadequate permissions for this operation.'
        redirect_to(project_path(@project))
        return
      end
      @cv_data0 = @cv_class.all
      @cv_data = @cv_data0.map{|d| d.attributes.update({:used=>false}) }
    else
      @project = parent
      if User.current.nil? || 
          !@project.users.include?(User.current) ||
          (!User.current.has_role?('Principal Investigator',@project) &&
          !User.current.has_role?('Data Manager',@project))
        flash[:notice] = 'You have inadequate permissions for this operation.'
        redirect_to(project_path(@project))
        return
      end
      
      @cv_data0 = @project.managed_repository{@cv_class.all}
      #@cv_data = @cv_data0.map{|d| d.attributes.update({:used=>!@project.sites.first(:variable_name_id=>d[:id]).nil?})}
      #@cv_data = @cv_data0.map{|d| 
      #  d.attributes.update({:used=>(!@project.sites.first(:lat_long_datum_id=>d[:id]).nil? || 
      #    !@project.sites.first(:local_projection_id=>d[:id]).nil?)})}
      if CV_MAP[@cv_type][:cv_list_refs].nil?
        @cv_data = @cv_data0.map{|d| d.attributes.update({:used=>false}) }
        @cv_columns = @cv_columns[0..-2] if @cv_columns[-1][:field]=="used"
      else
        @cv_data = @cv_data0.map{|d| d.attributes.update(CV_MAP[@cv_type][:cv_list_refs].call(d,@project)) }
      end
      
      #@copy_data = @cv_class.all(:id.not=>@cv_data0.collect(&:id)) #, :order=>[:term.asc])
      @copy_data = @cv_class.all #(:id.not=>@cv_data0.collect(&:id)) #, :order=>[:term.asc])
      @copy_columns = CV_MAP[@cv_type][:copy_columns]
    end
    ### 
    render 'voeis/cv_index.html.haml'
  end

  ### GET /cv_title2
  #alias :index :list

  ### HISTORY!
  def versions
    props = CV_MAP[@cv_type][:cv_properties].map{|x| x[:name].to_sym}
    cv_sym = CV_MAP[@cv_type][:cv_title2cv].to_sym
    cv_table = CV_MAP[@cv_type][:cv_title2cv]
    cv_table = cv_table[0..-4]+'cv' if cv_table[-3..-1]=='c_v'
    @cv_title = CV_MAP[@cv_type][:cv_title]
    @cv_title2 = CV_MAP[@cv_type][:cv_title2]
    @cv_id = CV_MAP[@cv_type][:cv_id]
    @cv_name = CV_MAP[@cv_type][:cv_name]
    @cv_term = CV_MAP[@cv_type][:cv_name]
    @cv_properties = CV_MAP[@cv_type][:cv_properties]
    if @cv_global
      @cv_item = @cv_class.get(params[:id])
      @cv_versions = @cv_item.versions.to_a
    else
      @project = parent
      @cv_item = @project.managed_repository{@cv_class.first(:id=>params[:id])}
      #@cv_versions = @project.managed_repository{Voeis::VerticalDatumCV.get(params[:id]).versions}
      #@cv_versions = @project.managed_repository{@cv_item.versions_array}
      #@cv_versions = @project.managed_repository.adapter.select("SELECT * FROM voeis_#{CV_MAP[@cv_type][:cv_table]}_versions WHERE id=%s ORDER BY updated_at DESC" % @cv_item.id)
      @cv_versions = @project.managed_repository.adapter.select("SELECT * FROM voeis_%s_versions WHERE id=%s ORDER BY updated_at DESC" % [cv_table,@cv_item.id])
    end
    if CV_MAP[@cv_type][:cv_ver_refs].nil?
      @cv_refs = []
    else
      @cv_refs = CV_MAP[@cv_type][:cv_ver_refs].call(@cv_item,@cv_versions)
    end
    #render 'spatial_references/versions.html.haml'
    render 'voeis/cv_versions.html.haml'
  end
  
  def invalid_page
    redirect_to(:back)
  end
end