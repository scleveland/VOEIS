class Voeis::SamplesController < Voeis::BaseController
  # Properly override defaults to ensure proper controller behavior
  # @see Voeis::BaseController
  defaults  :route_collection_name => 'samples',
            :route_instance_name => 'sample',
            :collection_name => 'samples',
            :instance_name => 'sample',
            :resource_class => Voeis::Sample
  
  has_widgets do |root|
    root << widget(:flot_graph)
  end

  def index
    @samples =  parent.managed_repository{Voeis::Sample.all(:order=>[:created_at.desc], :limit=>100)}
    @project = parent
  end

  def show
    @project = parent
    #@samples =  parent.managed_repository{Voeis::Sample.all}
    #@sample =  parent.managed_repository{Voeis::Sample.get(params[:id].to_i)}
    parent.managed_repository{
      @samples = Voeis::Sample.all
      @sample = Voeis::Sample.get(params[:id].to_i)
    }
    if !@sample.nil? 
      @site = @sample.sites[0]
    end
    @sample_properties = [
      {:label=>"Sample ID", :name=>"id"},
      {:label=>"Lab Code", :name=>"lab_sample_code"},
      {:label=>"Sample Type", :name=>"sample_type"},
      {:label=>"Sample Medium", :name=>"material"},
      {:label=>"Updated", :name=>"updated_at"},
      {:label=>"Updated By", :name=>"updated_by"},
      {:label=>"Update Comment", :name=>"updated_comment"},
      {:label=>"Created", :name=>"created_at"}
      ]
    
    #@project.managed_repository{
    #  @sample = Voeis::Sample.get(params[:id].to_i)
    #  @sites = Voeis::Site.all
    #  if !params[:site_id].nil?
    #    @site =  Voeis::Site.get(params[:site_id].to_i)
    #    @site_variable_stats = Voeis::SiteDataCatalog.all(:variable_id=>params[:id].to_i, :site_id=>params[:site_id].to_i)
    #    @graph_data = @variable.last_ten_values_graph(@site)
    #    @data = @variable.last_ten_values(@site)
    #    
    #    @TEST = 'TESTING controller'
    #  end
    #}
  end

  def new
    @project = parent
    @sample = @project.managed_repository{Voeis::Sample.new}
    @sample_types = Voeis::SampleTypeCV.all
    @sample_materials = Voeis::SampleMaterial.all
    @project_sample_materials = @project.managed_repository{Voeis::SampleMaterial.all}
    @sites = @project.managed_repository{Voeis::Site.all}
    @lab_methods = @project.managed_repository{Voeis::LabMethod.all}
    
    @label_array = Array["Sample Type","Lab Sample Code","Sample Medium","Site","Timestamp"]
    @current_samples = Array.new     
    @samples = @project.managed_repository{Voeis::Sample.all}
    @samples.all(:order => [:lab_sample_code.asc]).each do |samp|
       @temp_array = Array.new
       @temp_array=Array[samp.sample_type, samp.lab_sample_code, samp.material,samp.sites.first.name, samp.local_date_time.to_s]
       @current_samples << @temp_array
    end
  end

  def edit
    @sample =  parent.managed_repository{Voeis::Sample.get(params[:id])}
    @project = parent
  end

  def create
    puts "TIME"
    puts d_time = DateTime.parse("#{params[:time]["stamp(1i)"]}-#{params[:time]["stamp(2i)"]}-#{params[:time]["stamp(3i)"]}T#{params[:time]["stamp(4i)"]}:#{params[:time]["stamp(5i)"]}:00#{ActiveSupport::TimeZone[params[:time][:zone]].utc_offset/(60*60)}:00")
    parent.managed_repository do
      @sample = Voeis::Sample.new(:sample_type =>   params[:sample][:sample_type],
                                  :material => params[:sample][:material],
                                  :lab_sample_code => params[:sample][:lab_sample_code],
                                  :lab_method_id => params[:sample][:lab_method_id].to_i,
                                  :local_date_time => d_time)
                                  
      puts @sample.valid?
      puts @sample.errors.inspect()
      if @sample.save   
        @sample.sites << Voeis::Site.get(params[:site].to_i)
        @sample.save
        flash[:notice] = 'Sample was successfully created.'
        redirect_to :action => 'new'
      end
    end
  end

  def upload
    
  end

  def add_sample
    @samples = Sample.all
  end

  def save_sample
    puts "TIME"
    puts d_time = DateTime.parse("#{params[:time]["stamp(1i)"]}-#{params[:time]["stamp(2i)"]}-#{params[:time]["stamp(3i)"]}T#{params[:time]["stamp(4i)"]}:#{params[:time]["stamp(5i)"]}:00#{ActiveSupport::TimeZone[params[:time][:zone]].utc_offset/(60*60)}:00")
    sys_sample = Sample.first(:id => params[:sample])
    parent.managed_repository{Voeis::Sample.first_or_create(
    :sample_type=> sys_sample.sample_type,         
    :lab_sample_code=> sys_sample.sample_code,
    :lab_method_id=> sys_sample.lab_method_id,
    :local_date_time => d_time)}
    redirect_to project_url(parent)
  end
  
  def site_sample_variables
    parent.managed_repository do
      site = Voeis::Site.get(params[:site_id])
      @variable_hash = Hash.new
      i = 1
      @variable_hash['variables'] = Array.new
      @variable_hash['variables'] = site.variables.map do |var|
        if data_catalog = Voeis::SiteDataCatalog.first(:site_id => site.id, :variable_id => var.id)
          var_hash = Hash.new
          var_hash['id'] = var.id
          if !data_catalog.starting_timestamp.nil?
            var_hash['name'] = var.variable_name+":"+var.data_type + "(" + data_catalog.starting_timestamp.to_date.to_formatted_s(:long).gsub('00:00','') + " - " + data_catalog.ending_timestamp.to_date.to_formatted_s(:long).gsub('00:00','') + ')'
          else
            var_hash['name'] = var.variable_name+":"+var.data_type
          end
          var_hash
        end
        #@variable_hash['variables'] << @var_hash
      end
    end
    respond_to do |format|
       format.json do
         format.html
         render :json => @variable_hash.to_json, :callback => params[:jsoncallback]
       end
     end
  end
  
  def query
    #q = repository.adapter.send(:select_statement,VOEISMODELQUERY.query)
    #sql = q[0].gsub!("?").each_with_index{|v,i| "\'#{q[1][i]}\'" }
    
    siteid = params[:site_id]
    varid = params[:var_id]
    dt_start = params[:start_date]
    dt_end = params[:end_date]
    @project_uid= parent.id
    parent.managed_repository do
      @site = Voeis::Site.get(siteid) if !siteid.nil? && siteid.to_i>0
      
      # @start_year = Voeis::DataValue.first(:order => [:local_date_time.asc])
      # @end_year = Voeis::DataValue.last(:order => [:local_date_time.asc])
      
      @start_year = Voeis::SiteDataCatalog.first(:starting_timestamp.not => nil, :order => [:starting_timestamp.asc])
      @end_year = Voeis::SiteDataCatalog.last(:ending_timestamp.not => nil, :order => [:ending_timestamp.asc])
      
      #sensor_start_year = Voeis::SensorValue.first(:order => [:timestamp.asc])
      #sensor_end_year = Voeis::SensorValue.last(:order => [:timestamp.asc])
      if @start_year.nil? || @end_year.nil?
        @start_date = DateTime.now.strftime('%Y-%m-%d')
        @end_date = DateTime.now.strftime('%Y-%m-%d')
        @start_year = DateTime.now.year
        @end_year = DateTime.now.year
      else
        @start_date = @start_year.starting_timestamp.strftime('%Y-%m-%d')
        @end_date = @end_year.ending_timestamp.strftime('%Y-%m-%d')
        @start_year = @start_year.starting_timestamp.to_date.year
        @end_year = @end_year.ending_timestamp.to_date.year
      end

      @sites = Voeis::Site.all
        @variable_opt_array = Array.new
        if !@sites.empty?
          if !@sites.all(:order => [:name.asc]).first.variables.empty?
            #variable_opt_array << ["All", "All"]
            @sites.all(:order => [:name.asc]).first.variables.each do |var|
              data_catalog = Voeis::SiteDataCatalog.first(:site_id => @sites.all(:order => [:name.asc]).first.id, :variable_id => var.id)
              if !data_catalog.starting_timestamp.nil?
                @variable_opt_array << [var.variable_name+":"+var.data_type + "(" + data_catalog.starting_timestamp.to_date.to_formatted_s(:long).gsub('00:00','') + " - " + data_catalog.ending_timestamp.to_date.to_formatted_s(:long).gsub('00:00','') + ')', var.id.to_s]
              else
                @variable_opt_array << [var.variable_name+":"+var.data_type, var.id.to_s]
              end
            end
            @variable_count = @variable_opt_array.count
          else
            @variable_opt_array << ["None", "None"]
            @variable_count = 0
          end
        end
        @variable_opts = opts_for_select(@variable_opt_array, selected=varid)
      #end
    end
    logger.info "######### @variable_opts"
    logger.info @variable_opt_array
    
    @site_opts_array = Array.new
    @sites.all(:order => [:name.asc]).each do |site|
      @site_opts_array << [site.name.capitalize+" | "+site.code, site.id.to_s]
    end
    @site_options = opts_for_select(@site_opts_array,  selected=siteid)
  end
  
  
  def search
    @tabId = params[:tab_id]
    #@start_date =  Date.civil(params[:range][:"start_date(1i)"].to_i,params[:range]      [:"start_date(2i)"].to_i,params[:range][:"start_date(3i)"].to_i)
    #@end_date = Date.civil(params[:range][:"end_date(1i)"].to_i,params[:range]    [:"end_date(2i)"].to_i,params[:range][:"end_date(3i)"].to_i)
    @start_date =  Date.parse(params[:start_date])
    @end_date = Date.parse(params[:end_date])
    @start_date = @start_date.to_datetime
    @end_date = @end_date.to_datetime + 23.hour + 59.minute
    @project_uid = parent.id
    @data_set = parent.managed_repository{Voeis::DataSet.all}
    @data_set_opts_array = Array.new
    @data_set.all(:order => [:name.asc]).each do |ds|
      @data_set_opts_array << [ds.name.capitalize+' (DataSet)', ds.id.to_s]
    end
    @data_set_options = opts_for_select(@data_set_opts_array)
    @variables = parent.variables.all(:order=>[:variable_name.asc])
    @variables_opts_array = @variables.reject{|v| v.id.to_s==params[:varaible_select]}
      .map{|v| ["%s | %s [%s]"%[v.variable_name.slice(0,32),v.variable_units.units_abbreviation,v.id],v.id.to_s]}
    @variables_options = opts_for_select(@variables_opts_array)
    
    site = parent.managed_repository{Voeis::Site.get(params[:site_select])}
    @site_name = site.name
    @site = site
    if params[:variable] != "None"
      variable = parent.managed_repository{Voeis::Variable.get(params[:variable_select])}
      @var_name = variable.variable_name
      @variable = variable
      @units = Voeis::Unit.get(variable.variable_units_id).units_name
      @graph_data = Array.new
      @data_structs = ""  
      @meta_tags = ""
      parent.managed_repository do 
       # q = repository.adapter.send(:select_statement, Voeis::DataValue.all(:site_id => site.id, :variable_id => variable.id, :local_date_time.gte => @start_date, :local_date_time.lte => @end_date, :order=>[:local_date_time.asc],:fields=>[:id,:data_value,:local_date_time,:string_value,:datatype, :vertical_offset,:quality_control_level, :published, :date_time_utc, :site_id,:variable_id,:utc_offset,:end_vertical_offset, :value_accuracy,:replicate]).query)
        #sql = q[0].gsub!("?").each_with_index{|v,i| "\'#{q[1][i]}\'" }
        #@data_structs = repository.adapter.select(sql)
        standard_query = {:site_id => site.id, :variable_id => variable.id, :local_date_time.gte => @start_date, :local_date_time.lte => @end_date, :order=>[:local_date_time.asc],:fields=>[:id,:data_value,:local_date_time,:string_value,:datatype, :vertical_offset,:quality_control_level, :published, :date_time_utc, :site_id,:variable_id,:utc_offset,:end_vertical_offset, :value_accuracy,:replicate]}
        
        if params[:first_value_select] != "blank"
            temp_query1 = build_value_query_stmt(params[:first_value_select], params[:first_value_text])
          if params[:second_value_select] != "blank"
            temp_query2 = build_value_query_stmt(params[:second_value_select], params[:second_value_text])
            if params[:and_or_select] == "and"
              @data_structs = DataMapper.raw_select(Voeis::DataValue.all(standard_query) & (Voeis::DataValue.all(temp_query1) & Voeis::DataValue.all(temp_query2)))
              debugger
            else
              debugger
              @data_structs = DataMapper.raw_select(Voeis::DataValue.all(standard_query) & (Voeis::DataValue.all(temp_query1) | Voeis::DataValue.all(temp_query2)))
              
            end
          else
            @data_structs = DataMapper.raw_select(Voeis::DataValue.all(standard_query) & Voeis::DataValue.all(temp_query1))
          end
        else
          @data_structs = DataMapper.raw_select(Voeis::DataValue.all(standard_query))
        end
        
        
        
        @meta_tags = DataMapper.raw_select(Voeis::DataValueMetaTag.all(:data_value_id=>@data_structs.map{|d| d.id}))
      end
      @meta_tag_hash=Hash.new
      @data_structs.each do |data_val|
        @graph_data << Array[data_val.local_date_time.to_datetime.to_i*1000, data_val.data_value]
        #@meta_tag_hash[data_val.id] = @meta_tags.map{|m| m.data_value_id == data_val.id}.to_a
      end
      @scripts = parent.managed_repository{Voeis::Script.all}
      @scripts_opts_array = Array.new
      @scripts.all(:order=>[:name.asc]).each do |scr|
        @scripts_opts_array << ['>> '+scr.name, scr.id.to_s]
      end
      @scripts_options = opts_for_select(@scripts_opts_array)
      respond_to do |format|
        format.js if format.json
        format.html if format.html
      end#end format
    else
      @var_name = "None"
    end #end if !site.empty?
    
    ##@variables = parent.managed_repository{parent.variables}
    #@variables_opts_array = @variables.reject{|v| v.id==@variable.id}.map{|v| [v.variable_name,v.id.to_s]}
    #variables_opts_array = []
    #@variables.each do |v|
    #  variables_opts_array << [v.variable_name, v.id.to_s]
    #end
    #@variables_options = opts_for_select(@variables_opts_array)
    #@testing = "<option value='TEST'>TESTING-1-2-3</option>\n"
    #debugger
    
    #render 'search.html.haml'
  end #end def
  
  def opts_for_select(opt_array, selected = nil)
     option_string =""
     if !opt_array.empty?
       opt_array.each do |opt|
         if opt[1] == selected
           option_string = option_string + '<option selected="selected" value='+opt[1]+'>'+opt[0]+'</option>'
         else
           option_string = option_string + '<option value='+opt[1]+'>'+opt[0]+'</option>'
         end
       end
     end
     option_string
  end
  
  #export the results of search/browse to a csv file
  def export
    if params[:site_select]
      site=""
      variable=""
      parent.managed_repository do
        site = JSON[Voeis::Site.get(params[:site_select].to_i).to_json]
        variable = JSON[Voeis::Variable.get(params[:variable_select].to_i).to_json]
      end  
    else
      site = JSON[params[:site]]
      variable = JSON[params[:variable]]
    end #if params[:site_select]
    export_q = parent.managed_repository{repository.adapter.send(:select_statement, Voeis::DataValue.all(:site_id => site["id"].to_i, :variable_id => variable["id"].to_i, :local_date_time.gte => params[:start_date], :local_date_time.lte => params[:end_date], :order=>[:local_date_time.asc]).query)}
    export_sql = export_q[0].gsub!("?").each_with_index{|v,i| "\'#{export_q[1][i]}\'" }
    rows=JSON[parent.managed_repository{repository.adapter.select(export_sql).sql_to_json}]
    csv_string = CSV.generate do |csv|
      #csv << column_names
      csv<< ["Site Information"]
      csv<< site.keys
      csv<< site.values
      csv<< ["Variable Information"]
      csv<< variable.keys
      csv<< variable.values
      csv<< ["Data"]
      csv << rows.first.keys
      rows.each do |row|
        csv << row.values
      end
    end

    #csv_string =JSON[params[:data_vals]].to_csv
    filename = site["name"] + ".csv"
    send_data(csv_string,
      :type => 'text/csv; charset=utf-8; header=present',
      :filename => filename)
  end
  
  private
  
  def build_value_query_stmt(operation_name, value)
    result = case operation_name
      when "eql" then {:data_value=>value.to_f}
      when "gte" then {:data_value.gte=>value.to_f}
      when "lte" then {:data_value.lte=>value.to_f}
    end
  end
end
