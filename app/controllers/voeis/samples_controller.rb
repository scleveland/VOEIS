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
    @sample =  parent.managed_repository{Voeis::Sample.get(:params[:id])}
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
      site.variables.each do |var|
        data_catalog = Voeis::SiteDataCatalog.first(:site_id => site.id, :variable_id => var.id)
        @var_hash = Hash.new
        @var_hash['id'] = var.id
        @var_hash['name'] = var.variable_name+":"+var.data_type #+ "(" + data_catalog.starting_timestamp.to_date.to_formatted_s(:long).gsub('00:00','') + " - " + data_catalog.ending_timestamp.to_date.to_formatted_s(:long).gsub('00:00','') + ')'
        @variable_hash['variables'] << @var_hash
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
    parent.managed_repository do
      # @start_year = Voeis::DataValue.first(:order => [:local_date_time.asc])
      # @end_year = Voeis::DataValue.last(:order => [:local_date_time.asc])
      
      @start_year = Voeis::SiteDataCatalog.first(:starting_timestamp.not => nil, :order => [:starting_timestamp.asc])
      @end_year = Voeis::SiteDataCatalog.last(:ending_timestamp.not => nil, :order => [:ending_timestamp.asc])
      
      #sensor_start_year = Voeis::SensorValue.first(:order => [:timestamp.asc])
      #sensor_end_year = Voeis::SensorValue.last(:order => [:timestamp.asc])
      if @start_year.nil? || @end_year.nil?
        @start_year = Time.now.year
        @end_year = Time.now.year
      else
        @start_year = @start_year.starting_timestamp.to_time.year
        @end_year = @end_year.ending_timestamp.to_time.year
      end

      @sites = Voeis::Site.all
        variable_opt_array = Array.new
        if !@sites.empty?
          if !@sites.all(:order => [:name.asc]).first.variables.empty?
            #variable_opt_array << ["All", "All"]
            @sites.all(:order => [:name.asc]).first.variables.each do |var|
              variable_opt_array << [var.variable_name+":"+var.data_type, var.id.to_s]
            end
          else
            variable_opt_array << ["None", "None"]
          end
        end
        @variable_opts = opts_for_select(variable_opt_array)
      #end
    end
    @site_opts_array = Array.new
    @sites.all(:order => [:name.asc]).each do |site|
      @site_opts_array << [site.name.capitalize+" | "+site.code, site.id.to_s]
    end
    @site_options = opts_for_select(@site_opts_array)
  end
  
  
  
  def search
    @start_date =  Date.civil(params[:range][:"start_date(1i)"].to_i,params[:range]      [:"start_date(2i)"].to_i,params[:range][:"start_date(3i)"].to_i)
    @end_date = Date.civil(params[:range][:"end_date(1i)"].to_i,params[:range]    [:"end_date(2i)"].to_i,params[:range][:"end_date(3i)"].to_i)
    @start_date = @start_date.to_datetime
    @end_date = @end_date.to_datetime + 23.hour + 59.minute
    
    @column_array = Array.new
    @row_array = Array.new
    site = parent.managed_repository{Voeis::Site.get(params[:site])}
    @site_name =site.name
    if params[:variable] != "None"
      
      if params[:variable] == "All"
        @var_name = "All"
        timestamp_array = Array.new
        variable_hash = Hash.new #store all the datavalues[timestamp => datavalue] in and array 
        site.samples.variables.each do |variable|
          variable_hash[variable.id] = Hash.new
        end
        site.samples.variables.each do |variable|
          value = (site.samples.data_values(:local_date_time.gte => @start_date, :local_date_time.lte => @end_date) & variable.data_values).each do |val|
            val_hash = Hash.new
            val_hash[val.local_date_time.to_s] = val.string_value
            puts val_hash.to_json
            timestamp_array << val.local_date_time
            variable_hash[variable.id] = variable_hash[variable.id].merge(val_hash)
            puts variable_hash[variable.id].to_json
          end #val
        end #end variable
        
        @column_array = Array.new
        @column_array << ["Timestamp", 'datetime']
        variable_hash.keys.each do |key|
          puts "KEY: #{key}"
          var = parent.managed_repository{Voeis::Variable.get(key)}
          @column_array << [var.variable_name, 'number']
        end #end key
        timestamp_array.uniq.sort.each do |stamp|
          temp_array = Array.new
          temp_array << stamp
          variable_hash.keys.each do |key|
            puts variable_hash[key]
            if !variable_hash[key].nil?
              temp_array << variable_hash[key][stamp.to_s]
            end
          end #end var
          @row_array << temp_array
        end #end stamp
        puts "COLUMNARRAY: #{@column_array}"
        puts "ROWARRAY: #{@row_arrray}" 
      else #we want only one variable
        variable = parent.managed_repository{Voeis::Variable.get(params[:variable])}
        @var_name = variable.variable_name
        @units = Voeis::Unit.get(variable.variable_units_id).units_name
        # my_sample = nil
        # variable.samples.each do |sample|
        #   if sample.sites.first.id == site.id
        #     my_sample = sample
        #   end
        # end
        
        @grid_array = Array.new
        #if !my_sample.nil?
          @column_array << ["Timestamp", 'datetime']
          @column_array << ["Vertical Offset", 'number']
          @column_array << [variable.variable_name, 'number']
          #@data_vals = (variable.data_values(:local_date_time.gte => @start_date, :local_date_time.lte => @end_date) & site.data_values)
          @data_vals =parent.managed_repository{Voeis::DataValue.all(:site_id => site.id, :variable_id => variable.id, :local_date_time.gte => @start_date, :local_date_time.lte => @end_date)}
          @data_vals.all(:order=>[:local_date_time.asc]).each do |data_val|
            temp_array = Array.new
            row_hash = Hash.new
            temp_array << data_val.local_date_time.to_datetime
            row_hash[:datetime] = data_val.local_date_time.to_datetime
            row_hash[:unixtime] = data_val.local_date_time.to_datetime.to_i
            temp_array << data_val.vertical_offset
            row_hash[:vertical_offset] = data_val.vertical_offset
            temp_array << data_val.data_value
            row_hash[:value] = data_val.data_value
            @row_array << temp_array
            @grid_array << @row_hash.as_json
          end
        #end
        @graph_data = Array.new
        @data_vals.map{|d| @graph_data << Array[d.local_date_time.to_datetime.to_i*1000, d.data_value]}
      end #end if "ALL"
      if params[:export] == 1
         column_names = Array.new
         @column_array.each do |col|
           column_names << col[0]
         end#end col
         csv_string = CSV.generate do |csv|
           csv << column_names
           csv << @row_array
         end#end csv
         filename = site.name + ".csv"
         send_data(csv_string,
           :type => 'text/csv; charset=utf-8; header=present',
           :filename => filename)
      else
        respond_to do |format|
          format.js 
        end#end format
      end#end if export
    else
      @var_name = "None"
    end #end if !site.empty?
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
    headers = JSON[params[:column_array]]
    rows = JSON[params[:row_array]]
    column_names = Array.new
    headers.each do |col|
      column_names << col[0]
    end
    csv_string = CSV.generate do |csv|
      csv << column_names
      rows.each do |row|
        csv << row
      end
    end

    filename = params[:site_name] + ".csv"
    send_data(csv_string,
      :type => 'text/csv; charset=utf-8; header=present',
      :filename => filename)
  end
end
