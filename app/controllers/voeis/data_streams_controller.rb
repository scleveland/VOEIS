class Voeis::DataStreamsController < Voeis::BaseController

  # Properly override defaults to ensure proper controller behavior
  # @see Voeis::BaseController
  defaults  :route_collection_name => 'data_streams',
            :route_instance_name => 'data_stream',
            :collection_name => 'data_streams',
            :instance_name => 'data_stream',
            :resource_class => Voeis::DataStream


  def new
    @project = parent
    @data_templates = parent.managed_repository{Voeis::DataStream.all}
    respond_to do |format|
      format.html
    end
  end
  
  def destroy
    parent.managed_repository do
      data_stream = Voeis::DataStream.get(params[:id])
        respond_to do |format|
          if data_stream.destroy
            format.html{
              flash[:notice] = "Data Stream was deleted."
            }
            format.json{
              render :json => {:msg => "Data Stream was deleted."}, :callback => params[:jsoncallback]
            }
          else
            format.html{
              flash[:notice] = "Date Stream could not be deleted."
            }
            format.json{
              render :json => {:msg => data_stream.errors.inspect()}, :callback => params[:jsoncallback]
            }
          end #end if
        end #end respond
    end #end repo
  end

  # alows us to upload csv file to be processed into data
  # this requires that a datastream has already been created
  # to parse this file
  #
  # @example http://localhost:3000/project/upload/
  # curl -F datafile=@CR1000_2_BigSky_NFork_small.dat -F data_template_id=1 http://localhost:3000/projects/fbf20340-af15-11df-80e4-002500d43ea0/data_streams/
  # /?api_key=5c47e1d3ab117c4b009a65ed7ff346bc1e00dac9d56c64b0e61ecfd9a514806ea
  #
  # curl -X POST -F datafile=@CR1000_2_BigSky_NFork_small.dat -F data_template_id=1 http://localhost:3000/projects/fbf20340-af15-11df-80e4-002500d43ea0/data_streams/upload?api_key=5c47e1d3ab117c4b009a65ed7ff346bc1e00dac9d56c64b0e61ecfd9a514806e&
  #
  # @param [Hash] params
  # @option params [File] :datafile csv file to store
  # @option params [Integer] :DataStream ID
  #
  # @return [String] Accepts the upload of a CSV file
  #
  # @author Yogo Team
  #
  # @api public
  def upload
       logger.info{"AT THE BEGINNING OF UPLOAD"}
          first_row = Array.new
          flash_error = Hash.new
          name = Time.now.to_s + params[:datafile].original_filename 
          directory = "temp_data"
          @new_file = File.join(directory,name)
          File.open(@new_file, "wb"){ |f| f.write(params['datafile'].read)}
          begin 
              #data_stream_template = Voeis::DataStream.get(params[:data_template_id])
              start_line = parent.managed_repository{Voeis::DataStream.get(params[:data_template_id]).start_line}
              data_col_count = parent.managed_repository{Voeis::DataStream.get(params[:data_template_id]).data_stream_columns.count}
              site_id = parent.managed_repository{Voeis::DataStream.get(params[:data_template_id]).sites.first.id}
              logger.info {"FETCHED ******* Data Template start line:" + start_line.to_s}
              csv = CSV.open(@new_file, "r")
              (0..start_line).each do
                first_row = csv.readline
              end
              csv.close()
            if first_row.count == data_col_count
              flash_error = flash_error.merge(parent.managed_repository{Voeis::SensorValue.parse_logger_csv(@new_file, params[:data_template_id], site_id)})
            else
              #the file does not match the data_templates number of columns
              flash_error[:error] = "File does not match the data_templates number of columns."
              logger.info {"File does not match the data_templates number of columns."}
            end
          rescue Exception => e
            logger.info {e.to_s}
            #problem parsing file
            flash_error[:error] = "There was a problem parsing this file."
            logger.info {"There was a problem parsing this file."}
          end
        #parent.publish_his
        respond_to do |format|
          if params.has_key?(:api_key)
            format.json
          end
          if flash_error[:error].nil?
            flash[:notice] = "File was parsed succesfully."
          else
            flash[:warning] = flash_error[:error]
          end
          format.html { redirect_to(project_path(parent)) }
        end
  end

  def add
    @project = parent
    @data_templates = parent.managed_repository{Voeis::DataStream.all}
    respond_to do |format|
      format.html
    end
  end

  def data
    # params[:start_date]
    # params[:end_date]
    # params[:variable_ids]
    # params[:hourly]
    # params[:hours]
    # params[:data_stream_ids]
    # if !params[:all].nil?
    #       #get everything in the project
    #     else
      #get the data_stream
      puts "before*************************************************"
      if !params[:data_stream_ids].empty?
        puts "here1"
        params[:data_stream_ids].each do |data_stream_id|
          data_stream = parent.managed_repository{Voeis::DataStream.get(data_stream_id)}
          site = data_stream.sites.first
          @download_meta_array = Array.new
          @sensor_hash = Hash.new
          data_stream.data_stream_columns.all(:order => [:column_number.asc]).each do |data_col|
            puts "here2"
            @value_array= array.new
            sensor = data_col.sensor_types.first
            params[:variable_ids].each do |var_id|
              if sensor.variables.first.id == var_id
                if !params[:start_date].nil? && !params[:end_date].nil?
                  sensor.sensor_values(:timestamp.gte => params[:start_date],:timestamp.lte => params[:end_date], :order => (:timestamp.asc)).each do |val|
                    @value_array << [val.timestamp, val.value]
                  end #end do val
                elsif !params[:hours]
                  last_date = sensor.sensor_values.last(:order => [:timestamp.asc]).timestamp
                  start_date = (last_date.to_time - params[:hours].to_i.hours).to_datetime
                  sensor.sensor_values(:timestamp.gte => start_date, :order => (:timestamp.asc)).each do |val|
                    @value_array << [val.timestamp, val.value]
                  end #end do val
                end #end if
                @data_hash = Hash.new
                @data_hash[:data] = @value_array
                @sensor_meta_array = Array.new
                variable = sensor.variables.first
                @sensor_meta_array << [{:variable => variable.variable_name},
                                       {:units => Voeis::Unit.get(variable.variable_units_id)},
                                       @data_hash]
                @sensor_hash[sensor.name] = @sensor_meta_array
              end #end if
            end #end do var_id
          end #end do data col
          @download_meta_array = [{:site => site.name},
                                  {:site_code => site.code},
                                  {:lat => site.latitude},
                                  {:longitude => site.longitude},
                                  {:sensors => @sensor_hash}]
        end #end do data_stream
      end # end if
    # end
    respond_to do |format|
      format.json do
        render :json => @download_meta_array, :callback => params[:jsoncallback]
      end
    end
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
  
  def site_data_stream_options(site_id)
    
    @data_stream_array = Array.new
    parent.managed_repository do
      site= Voeis::Site.get(site_id)
      if !site.nil?
        site.data_streams.all(:order => [:name.asc]).each do |data_stream|
          @data_stream_hash = Hash.new
          @data_stream_hash['id'] = data_stream.id.to_s
          @data_stream_hash['name'] =  data_stream.name.capitalize
          @data_stream_array << @data_stream_hash
        end
      else
        @data_stream_hash = Hash.new
        @data_stream_hash['id'] ="None"
        @data_stream_hash['name'] = "None"
        @data_stream_array << @data_stream_hash
      end
    end
    return @data_stream_array
  end
  
  
  
  def data_stream_var_options (data_stream_id)
    @units  = Voeis::Unit.all
    @variable_array = Array.new
    parent.managed_repository do
      data_stream = Voeis::DataStream.get(data_stream_id)
      @variable_hash = Hash.new
      i = 1
      if !data_stream.nil?
         #@variable_hash ['id'] = "All"
         #@variable_hash['name'] = "All"
         #@variable_array << @variable_hash
         data_stream.data_stream_columns.sensor_types.each do |sensor|
           var = sensor.variables.first
           if !var.nil?
             @var_hash = Hash.new
             @var_hash['id'] = var.id.to_s + "," + sensor.data_stream_columns.data_streams.first.id.to_s
             unit_abbreviation = @units.first(:id => var.variable_units_id).nil? ? "NA" : @units.first(:id => var.variable_units_id).units_abbreviation.to_s 
             @var_hash['name'] = var.variable_name+":"+var.variable_code+":"+var.sample_medium+":"+var.data_type+":"+unit_abbreviation.to_s+":"+sensor.data_stream_columns.data_streams.first.name
             @variable_array << @var_hash
           end
         end
      else
        @var_hash = Hash.new
        @var_hash['id'] ="None"
        @var_hash['name'] = "None"
        @variable_array << @var_hash
      end
    end
    return @variable_array
  end
  
  def data_stream_sensor_variables
    @variable_hash = Hash.new
    @variable_hash= {"variables" => data_stream_var_options(params[:data_stream_id])}
    respond_to do |format|
       format.json do
         format.html
         render :json => @variable_hash.to_json, :callback => params[:jsoncallback]
       end
     end
  end
  def site_data_streams
    @data_stream_hash = Hash.new
    @data_stream_hash ={"data_streams" => site_data_stream_options(params[:site_id])}
    respond_to do |format|
       format.json do
         format.html
         render :json => @data_stream_hash.to_json, :callback => params[:jsoncallback]
       end
     end
  end

  def query
    @variables = ""
    @sites = ""
    @start_year=""
    @end_year =""
   
    @units = Voeis::Unit.all
    parent.managed_repository do
      @sites = Voeis::Site.all
      @start_year = Voeis::SensorValue.first(:order => [:timestamp.asc])
      @end_year = Voeis::SensorValue.last(:order => [:timestamp.asc])
      if @start_year.nil? || @end_year.nil?
        @start_year = Time.now.year
        @end_year = Time.now.year
      else
        @start_year = @start_year.timestamp.to_time.year
        @end_year = @end_year.timestamp.to_time.year
      end
      @data_stream_opts_array = Array.new
      site_data_stream_options(@sites.all(:order => [:name.asc]).first.id).each do |ds|
        @data_stream_opts_array << [ds['name'], ds['id']]
      end
      @variable_opts_array = Array.new
      #if !@data_stream_opts_array.nil?
      #  data_stream_var_options(@data_stream_opts_array.sort[0][1]).each do |var|
      #    @variable_opts_array << [var['name'], var['id']]
      #  end
      #end
    end
    @site_opts_array = Array.new
    @sites.all(:order => [:name.asc]).each do |site|
      @site_opts_array << [site.name.capitalize+" | "+site.code, site.id.to_s]
    end
    #@site_options = options_for_select(@site_opts_array)
  end

  def search
    puts 'Export:'+params[:export].to_s
    @start_date =  Date.civil(params[:range][:"start_date(1i)"].to_i,params[:range]      [:"start_date(2i)"].to_i,params[:range][:"start_date(3i)"].to_i)
    @end_date = Date.civil(params[:range][:"end_date(1i)"].to_i,params[:range]    [:"end_date(2i)"].to_i,params[:range][:"end_date(3i)"].to_i)
    
    @start_date = @start_date.to_datetime
    @end_date = @end_date.to_datetime + 23.hour + 59.minute
    if !params[:variable].empty? && !params[:site].empty?
      @column_array = Array.new
      @row_array = Array.new
      @value_array = Array.new
      site = parent.managed_repository{Voeis::Site.get(params[:site])}
      @site_name =site.name
      var_datastream = params[:variable].split(",")
      variable = parent.managed_repository{Voeis::Variable.get(var_datastream[0])}
      datastream = parent.managed_repository{Voeis::DataStream.get(var_datastream[1])}
      if datastream.nil?
        datastream = parent.managed_repository{Voeis::DataStream.first}
      end
      if params[:variable] == "All"
        @var_name = "All"
      elsif params[:variable] == "None"
        @var_name = "None"
      elsif var_datastream[0] == "All"
        @var_name = "ALL:"+datastream.name
      else
        @var_name = variable.variable_name
      end
      # if !parent.manged_repository{Voeis::Variable.get(params[:variable]).sensor_types.all(:sites => {:id => site.id})}.nil?
      if !site.sensor_types.empty? && params[:variable] != "None"
        if @var_name == "All"
          @column_array << ["Timestamp", 'datetime']
          @column_array << ["Vertical Offset", 'number']
          site.sensor_types.each do |sensor|
            
            @column_array << [sensor.variables.first.variable_name, 'number']
          end
          @dvalues = site.sensor_types.first.sensor_values(:timestamp.gte => @start_date.to_datetime, :timestamp.lte => @end_date.to_datetime)
          @dvalues.each do |sens_val|
            temp_array = Array.new
            temp_hash = Hash.new
            temp_hash["timestamp"] = sens_val.timestamp.to_datetime
            temp_hash["vertical_offset"] =sens_val.timestamp.to_datetime
            temp_array << sens_val.timestamp.to_datetime
            temp_array << sens_val.vertical_offset
            if !sens_val.nil?
              temp_array << sens_val.value
              temp_hash["value"] = sens_val.value
            else
              temp_array << -9999.0
              temp_hash["value"] = "NA"
            end
            @row_array << temp_array
            @value_array << temp_hash
          end
        elsif var_datastream[0] == "All"
          debugger
          @column_array << ["Timestamp", 'datetime']
          @column_array << ["Vertical Offset", 'number']
          datastream.data_stream_columns.sensor_types.all(:order => [:name.asc]).each do |sensor|
            @column_array << [sensor.variables.first.variable_name, 'number']
          end
          @dvalues = site.sensor_types.first.sensor_values(:timestamp.gte => @start_date.to_datetime, :timestamp.lte => @end_date.to_datetime)
          @dvalues.each do |sens_val|
            temp_array = Array.new
            temp_array << sens_val.timestamp.to_datetime
            temp_array << sens_val.vertical_offset
            site.sensor_types.all(:order => [:name.asc]).each do |sens|
              val = sens.sensor_values.first(:timestamp.gte => sens_val.timestamp)
              if !val.nil?
                temp_array << val.value
              else
                temp_array << -9999.0
              end
            end
            @row_array << temp_array
          end
        else
          my_sensor =""
          
          my_sensor = datastream.data_stream_columns.sensor_types.intersection(variable.sensor_types)#.each do |sensor|
            #if sensor.sites.first.id == site.id
              #my_sensor = sensor
            #end
          #end
          if !my_sensor.nil?
            @column_array << ["Timestamp", 'datetime']
            @column_array << ["Vertical Offset", 'number']
            @column_array << [my_sensor.variables.first.variable_name, 'number']
            @dvalues = my_sensor.sensor_values(:timestamp.gte => @start_date.to_datetime, :timestamp.lte => @end_date.to_datetime).each do |sens_val|
              temp_array = Array.new
              temp_hash = Hash.new
              temp_array << sens_val.timestamp.to_datetime
              temp_array << sens_val.vertical_offset
              temp_hash["timestamp"] = sens_val.timestamp.to_datetime
              temp_hash["vertical_offset"] =sens_val.timestamp.to_datetime
              temp_hash["value"] = sens_val.value
              temp_array << sens_val.value
              @row_array << temp_array
              @value_array << temp_hash
            end
            # @value_hash{identifier: 'id',
            # label: 'name',
            # items: #{value_array.as_json} };}
          # elsif !sensor1.nil?
          #   @column_array << [sensor1.variables.first.variable_name, 'number']
          #   sensor.sensor_values.each do |sens_val|
          #     temp_array = Array.new
          #     temp_array << sens_val.timestamp.to_datetime
          #     temp_array << sens_val.value
          #     @row_array << temp_array
          #   end
          end
        end
      end
      if params[:export] == 1

         column_names = Array.new
         @column_array.each do |col|
           column_names << col[0]
         end
         csv_string = CSV.generate do |csv|
           csv << column_names
           csv << @row_array
         end

         filename = site.name + ".csv"
         send_data(csv_string,
           :type => 'text/csv; charset=utf-8; header=present',
           :filename => filename)
      else
        respond_to do |format|
          format.js 
        end
      end
    end
  end

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

  # alows us to upload csv file to be processed into data
  #
  # @example http://localhost:3000/project/upload_stream/1/
  #
  # @param [Hash] params
  # @option params [Hash] :upload
  #
  # @return [String] Accepts the upload of a CSV file
  #
  # @author Yogo Team
  #
  # @api public
  def pre_upload
    @project = parent

    @variables = Voeis::Variable.all
    @sites = parent.managed_repository{ Voeis::Site.all }
    if !params[:datafile].nil? && datafile = params[:datafile]
      # if ! ['text/csv', 'text/comma-separated-values', 'application/vnd.ms-excel',
      #             'application/octet-stream','application/csv'].include?(datafile.content_type)
      #         flash[:error] = "File type #{datafile.content_type} not allowed"
      #         redirect_to(:controller =>"voeis/data_streams", :action => "new", :params => {:id => params[:project_id]})
      #         return true
      #       else
        file_name = Time.now.to_s + params['datafile'].original_filename
        directory = "temp_data"
        @new_file = File.join(directory,file_name)
        File.open(@new_file, "wb"){ |f| f.write(params['datafile'].read)}
        # Read the logger file header
        if params[:header_box] == "Campbell"
          @start_line = 4
          @header_info = parse_logger_csv_header(@new_file)

          @start_row = @header_info.last
          @row_size = @start_row.size - 1
          if @header_info.empty?
            flash[:error] = "CSV File improperly formatted. Data not uploaded."
            #redirect_to :controller =>"projects", :action => "add_stream", :params => {:id => params[:project_id]}
          end
        else
          @start_line = params[:start_line].to_i
          @start_row = get_row(@new_file, params[:start_line].to_i)
          @row_size = @start_row.size-1
        end
      
      @var_array = Array.new
      @var_array[0] = ["","","","","","",""]
      @opts_array = Array.new
      @variables.all(:order => [:variable_name.asc]).each do |var|
        @opts_array << [var.variable_name+":"+var.variable_code+":"+var.sample_medium+':'+ var.data_type+':'+Voeis::Unit.get(var.variable_units_id).units_name, var.id.to_s]
      end
      if params[:data_template] != "None"
          data_template = parent.managed_repository {Voeis::DataStream.first(:id => params[:data_template])}
          (0..@row_size).each do |i|
             puts i
             if !data_template.data_stream_columns.first(:column_number => i).nil?
               data_col = data_template.data_stream_columns.first(:column_number => i)
               if data_col.name != "Timestamp" 
                 if data_col.variables.empty?
                   @var_array[i] = [data_col.original_var, data_col.unit, data_col.type,opts_for_select(@opts_array),"", "", "",data_col.name]
                 else
                   @var_array[i] = [data_col.original_var, data_col.unit, data_col.type,opts_for_select(@opts_array,Voeis::Variable.first(:variable_code => data_col.variables.first.variable_code).id.to_s),data_col.sensor_types.first.min, data_col.sensor_types.first.max, data_col.sensor_types.first.difference,data_col.name]
                 end
                else
                  @var_array[i] = [data_col.original_var, data_col.unit, data_col.type,opts_for_select(@opts_array),"","","",""]
                end
              else
                @var_array[i] = ["","","",opts_for_select(@opts_array),"","","",""]
              end
          end
      else
        (0..@row_size).each do |i|
          @var_array[i] = ["","","",opts_for_select(@opts_array),"","",""]
         end
      end
    end
  end



  def create_stream
    #create and save new DataStream
    data_stream =""
    site =""
    redirect_path =Hash.new
    data_stream=""
    parent.managed_repository do
      data_stream = Voeis::DataStream.first_or_create(:name => params[:data_stream_name],
        :description => params[:data_stream_description],
        :filename => params[:datafile],
        :start_line => params[:start_line].to_i)
      puts data_stream.errors.inspect
      #Add site association to data_stream
      #
      site = Voeis::Site.first(:id => params[:site])
      data_stream.sites << site
      data_stream.save
      # site.data_streams << data_stream
      #     site.save
      #create DataStreamColumns
      #
    end
    range = params[:rows].to_i
    (0..range).each do |i|
      #create the Timestamp column
      if i == params[:timestamp].to_i && params[:timestamp] != "None"
        parent.managed_repository do
          data_stream_column = Voeis::DataStreamColumn.create(
                                :column_number => i,
                                :name => "Timestamp",
                                :type =>"Timestamp",
                                :unit => "NA",
                                :original_var => params["variable"+i.to_s])
          data_stream_column.data_streams << data_stream
          data_stream_column.save
        end
      elsif i == params[:date].to_i && params[:date] != "None"
        parent.managed_repository do
          data_stream_column = Voeis::DataStreamColumn.create(
                                :column_number => i,
                                :name => "Date",
                                :type =>"Date",
                                :unit => "NA",
                                :original_var => params["variable"+i.to_s])
          data_stream_column.data_streams << data_stream
          data_stream_column.save
        end
      elsif i == params[:time].to_i && params[:time] != "None"
        parent.managed_repository do
          data_stream_column = Voeis::DataStreamColumn.create(
                                :column_number => i,
                                :name => "Time",
                                :type =>"Time",
                                :unit => "NA",
                                :original_var => params["variable"+i.to_s])
          data_stream_column.data_streams << data_stream
          data_stream_column.save
        end
      elsif i == params[:vertical_offset].to_i
        parent.managed_repository do
          data_stream_column = Voeis::DataStreamColumn.create(
                                :column_number => i,
                                :name => "Vertical-Offset",
                                :type =>"Offset",
                                :unit => "NA",
                                :original_var => params["variable"+i.to_s])
          data_stream_column.data_streams << data_stream
          data_stream_column.save
        end
      else #create other data_stream_columns and create sensor_types
        #puts params["column"+i.to_s]
        var = Voeis::Variable.get(params["column"+i.to_s])
        parent.managed_repository do
          data_stream_column = Voeis::DataStreamColumn.create(
                                :column_number => i,
                                :name =>         params["variable"+i.to_s].empty? ? "unknown" : params["variable"+i.to_s],
                                :original_var => params["variable"+i.to_s].empty? ? "unknown" : params["variable"+i.to_s],
                                :unit =>         "NA",
                                :type =>         params["type"+i.to_s].empty? ? "unknown" : params["type"+i.to_s])
          if !params["ignore"+i.to_s]            
            variable = Voeis::Variable.first_or_create(
                        :variable_code => var.variable_code,
                        :variable_name => var.variable_name,
                        :speciation =>  var.speciation,
                        :variable_units_id => var.variable_units_id,
                        :sample_medium =>  var.sample_medium,
                        :value_type => var.value_type,
                        :is_regular => var.is_regular,
                        :time_support => var.time_support,
                        :time_units_id => var.time_units_id,
                        :data_type => var.data_type,
                        :general_category => var.general_category,
                        :no_data_value => var.no_data_value)
            data_stream_column.variables << variable
            data_stream_column.data_streams << data_stream
            data_stream_column.save
            #create a new sensor for each data_stream_column - should only have one data_stream_column associated with it ever.
             sensor_type = Voeis::SensorType.create(
                           :name => params["variable"+i.to_s].empty? ? "unknown" + site.name : params["variable"+i.to_s] + site.name,
                           :min => params["min"+i.to_s].to_f,
                           :max => params["max"+i.to_s].to_f,
                           :difference => params["difference"+i.to_s].to_f)
             #Add sites and variable associations to senor_type
             #
             sensor_type.sites << site
             sensor_type.variables <<  variable
             sensor_type.data_stream_columns << data_stream_column
             sensor_type.save
             site.variables << variable
             site.save
           else
             data_stream_column.name = "ignore"
             data_stream_column.data_streams << data_stream
             data_stream_column.save
          end #end if
        end #end managed repository
      end #end if
    end #end range.each
    # Parse the csv file using the newly created data_stream template and
    # save the values as sensor_values
    parent.managed_repository{Voeis::SensorValue.parse_logger_csv(params[:datafile], data_stream.id, site.id,  data_stream.start_line)}
    # parent.publish_his
     flash[:notice] = "File parsed and stored successfully."
     redirect_to project_path(params[:project_id])
  end

  # def index
  #   @project_array = Array.new
  #   parent.managed_repository do
  #     @sites = Voeis::Site.all
  #     @project_hash = Hash.new
  #     @site_data = Hash.new
  #     num_hash = Hash.new
  #     site_count=-1
  #     @sites.each do |site|
  #       site_count +=1
  #       @plot_data = "{"
  #       senscount = 0
  #       @site_hash = Hash.new
  #       @sensor_types = site.sensor_types
  #       @sensor_types.each do |s_type|
  #         if !s_type.sensor_values.empty?
  #         if senscount != 0 &&
  #          @plot_data +=  ","
  #         end
  #         senscount+=1
  #         count = 0
  # 
  #         @plot_data += '"' + s_type.name + "-" + site.code + '"' + ": {data:["
  #         @sensor_hash = Hash.new
  #         num = 24
  #         cur_date = s_type.sensor_values.first(:order => [:timestamp.desc]).timestamp
  #         begin_date = (cur_date.to_time - num.hours).to_datetime
  #         tmp_data = ""
  #         sense_data = s_type.sensor_values(:timestamp.gt => begin_date, :timestamp.lt => cur_date)
  #         sense_data.each do |val|
  #           tmp_data = tmp_data + ",[" + (val.timestamp.to_time.to_i*1000).to_s + ","                        + val.value.to_s + "]"
  #         end
  #         tmp_data = tmp_data.slice(1..tmp_data.length)
  #         array_data = Array.new()
  #         puts value_results = s_type.sensor_values(:timestamp.gt => begin_date, :timestamp.lt => cur_date).collect{
  #         |val|
  #            temp_array= Array.new()
  #            if params[:hourly].nil?
  #              temp_array.push(val.timestamp.to_time.to_i*1000, val.value)
  #              array_data.push(temp_array)
  #            else
  #              if val.timestamp.min == 0
  #                temp_array.push(val.timestamp.to_time.localtime.to_i*1000, val.value)
  #                array_data.push(temp_array)
  #              end
  #            end
  #          }
  #          if !tmp_data.nil?
  #            @plot_data += tmp_data
  #          end
  #          @sensor_hash["data"] = array_data
  #          @sensor_hash["label"] = s_type.variables.first.variable_name
  #          @thelabel = s_type.variables.first.variable_name
  #          if !s_type.sensor_values.last.units.nil?
  #            @sensor_hash["units"] = s_type.sensor_values.last.units
  #          else
  #            @sensor_hash["units"] = "nil"
  #          end
  #          @site_hash[s_type.name] = @sensor_hash
  #          @plot_data += "] , label: \"#{@thelabel}\" }"
  #         end
  #       end #end sensor_type
  #       @plot_data += "}"
  #       temp_hash = Hash.new
  #       temp_hash["sitecode"]=site.code
  #       temp_hash["sitename"]=site.name
  #       temp_hash["sensors"]=@site_hash
  #       @project_array.push(temp_hash)
  #       num_hash[site.code] = site_count
  #       @site_data[site.code] = @plot_data
  #     end  #site
  #     @project_hash["sites"] = @project_array
  #   end
  #   respond_to do |format|
  #     format.html
  #   end
  # end


   # parse the header of a logger file
   # assumes Campbell scientific header style at the moment
   # @example parse_logger_csv_header("filename")
   #
   # @param [String] csv_file
   #
   # @return [Array] an array whose elements are a hash
   #
   # @author Yogo Team
   #
   # @api public
   def parse_logger_csv_header(csv_file)
     csv_data = CSV.read(csv_file)
     path = File.dirname(csv_file)

     #look at the first hour lines -
     #line 0 is a description -so skip that one
     #line 1 is the variable names
     #line 2 is the units
     #line 3 is the type
     #store the variable,unit and type for a column as a hash in an array
     header_data=Array.new
     (0..csv_data[1].size-1).each do |i|
       item_hash = Hash.new
       item_hash["variable"] = csv_data[1][i].to_s
       item_hash["unit"] = csv_data[2][i].to_s
       item_hash["type"] = csv_data[3][i].to_s
       header_data << item_hash
     end

     header_data << csv_data[4]
   end

   # Returns the specified row of a csv
   #
   # @example get_row("filename",4)
   #
   # @param [String] csv_file
   # @param [Integer] row
   #
   # @return [Array] an array whose elements are a csv-row columns
   #
   # @author Yogo Team
   #
   # @api public
   def get_row(csv_file, row)
     csv_data = CSV.read(csv_file)
     path = File.dirname(csv_file)

     csv_data[row-1]
   end
   
end
