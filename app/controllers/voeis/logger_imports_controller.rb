class Voeis::LoggerImportsController < Voeis::BaseController
  
  defaults  :route_collection_name => 'logger_imports',
            :route_instance_name => 'logger_import',
            :collection_name => 'logger_imports',
            :instance_name => 'logger_import'


  def new
     @project = parent
     @sites = parent.managed_repository{Voeis::Site.all}
     @data_templates = parent.managed_repository{Voeis::DataStream.all(:type => "Sensor")}
     respond_to do |format|
       format.html
     end
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
    else
        redirect_to(:controller =>"voeis/logger_imports", :action => "new", :params => {:id => params[:project_id]})
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
             # variable = Voeis::Variable.first_or_create(
             #             :variable_code => var.variable_code,
             #             :variable_name => var.variable_name,
             #             :speciation =>  var.speciation,
             #             :variable_units_id => var.variable_units_id,
             #             :sample_medium =>  var.sample_medium,
             #             :value_type => var.value_type,
             #             :is_regular => var.is_regular,
             #             :time_support => var.time_support,
             #             :time_units_id => var.time_units_id,
             #             :data_type => var.data_type,
             #             :general_category => var.general_category,
             #             :no_data_value => var.no_data_value)
             if Voeis::Variable.get(var.id).nil?
               variable = Voeis::Variable.new
               variable.attributes = var.attributes
               variable.save!
             else
              variable = Voeis::Variable.get(var.id)
             end
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
   
   ###########################################################################################
   
   # Gather information necessary to store logger data
   #
   #
   #
   # @author Sean Cleveland
   #
   # @api public
   def pre_process_logger_file_upload
     @project = parent
     @data_templates = parent.managed_repository{Voeis::DataStream.all(:type => "Sensor")}
     @general_categories = Voeis::GeneralCategoryCV.all
     @sites = parent.managed_repository{Voeis::Site.all}
   end
   
   # pre_process_logger_files
   # This is the Logger Wizard Upload Second Step for describing how to parse a CSV file
   # @author Sean Cleveland
   # @api public
   def pre_process_logger_file

        require 'csv_helper'
        @data_template = parent.managed_repository{Voeis::DataStream.get(params[:data_template_id].to_i)}  
        @project = parent
        @current_user = current_user
        #save uploaded file if possible
        if !params[:datafile].nil? && datafile = params[:datafile]
          if ! ['text/csv', 'text/comma-separated-values', 'application/vnd.ms-excel',
                'application/octet-stream','application/csv'].include?(datafile.content_type)
            flash[:error] = "File type #{datafile.content_type} not allowed"
            redirect_to(:controller =>"voeis/logger_imports", :action => "pre_process_logger_file_upload", :params => {:id => params[:project_id]})

          else
            #file can be saved
            name = Time.now.to_s + params['datafile'].original_filename
            directory = "temp_data"
            @new_file = File.join(directory,name)
            File.open(@new_file, "wb"){ |f| f.write(params['datafile'].read)}

            @start_line = params[:start_line].to_i
            if params[:header_box] == "Campbell"
              @start_line = 5
            end
            #get the first row that has information in the CSV file
            @start_row = get_row(@new_file, @start_line)
            @row_size = @start_row.size-1

            @header_rows = @start_line < 2 ? -1 : @start_line -2


            @columns = Array.new
            (1..@start_row.size).map{|x| @columns << x}
            @vars = Hash.new

            Voeis::Variable.all.each do |v| 

              @vars=@vars.merge({v.variable_name => v.id})
            end



            # @site_offset = Hash.new
            # @sites = {"None"=>"None"}
            # parent.managed_repository{Voeis::Site.all}.each do |s|
            #   @sites = @sites.merge({s.name => s.id})
            #   @site_offset = @site_offset.merge({s.id => s.time_zone_offset})
            #   if s.time_zone_offset.to_s == "unknown"
            #     begin
            #       s.fetch_time_zone_offset
            #     rescue
            #       #do nothing
            #     end
            #   end
            # end
            @site = parent.managed_repository{Voeis::Site.get(params[:site_id].to_i)}
            if @site.time_zone_offset.to_s == "unknown" || @site.time_zone_offset.nil?
              begin
                @site.fetch_time_zone_offset
              rescue
                #do nothing
              end
            end
            @utc_offset_options=Hash.new
            (-12..12).map{|k| @utc_offset_options = @utc_offset_options.merge({k => k})}           
            @sources = {"None"=>"None", "Example:SampleName"=>-1}
             Voeis::Source.all.each do |s|
               @sources = @sources.merge({s.organization + ':' + s.contact_name => s.id})
             end

            @variables = Voeis::Variable.all
            @var_properties = Array.new
            Voeis::Variable.properties.each do |prop|

              @var_properties << prop.name
            end
            @var_properties.delete_if {|x| x.to_s == "id" || x.to_s == "his_id" || x.to_s == "time_units_id" || x.to_s == "is_regular" || x.to_s == "time_support" || x.to_s == "variable_code" || x.to_s == "created_at" || x.to_s == "updated_at" || x.to_s == "updated_by" || x.to_s == "updated_comment"}

            @campbell_scientific = params[:header_box]
            @variable = Voeis::Variable.new
            @lab_methods = Voeis::LabMethod.all
            @field_methods = Voeis::FieldMethod.all
            @units = Voeis::Unit.all
            @offset_units = @units
            @spatial_offset_types = Voeis::SpatialOffsetType.all
            @time_units = Voeis::Unit.all(:units_type.like=>'%Time%')
            @variable_names = Voeis::VariableNameCV.all
            @quality_control_levels = Voeis::QualityControlLevel.all
            @sample_mediums= Voeis::SampleMediumCV.all
            @sample_types = Voeis::SampleTypeCV.all
            @sensor_types = Voeis::SensorTypeCV.all
            @logger_types = Voeis::LoggerTypeCV.all
            @value_types= Voeis::ValueTypeCV.all
            @speciations = Voeis::SpeciationCV.all
            @data_types = Voeis::DataTypeCV.all
            @general_categories = Voeis::GeneralCategoryCV.all
            @batch = Voeis::MetaTag.first_or_create(:name => "Batch", :category =>"Chemistry", :value=>"")
             @labs = Voeis::Lab.all

             
            @label_array = Array["Variable Name","Variable Code","Unit Name","Speciation","Sample Medium","Value Type","Is Regular","Time Support","Time Unit ID","Data Type","General Cateogry"]
            @current_variables = Array.new     
            @variables.all(:order => [:variable_name.asc]).each do |var|
              @temp_array =Array[var.variable_name, var.variable_code,@units.get(var.variable_units_id).units_name, var.speciation,var.sample_medium, var.value_type, var.is_regular.to_s, var.time_support.to_s, var.time_units_id.to_s, var.data_type, var.general_category]
              @current_variables << @temp_array
            end

            #parse csv file into array
            @csv_array = Array.new
            csv_data = CSV.read(@new_file)
            i = 0
            csv_data[0..-1].each do |row|
              temp_array = Array.new
              row.map! { |k| temp_array << k }
              @csv_array[i] = temp_array
              i = i + 1
            end
            @csv_size = i -1
          end       

        else
            redirect_to(:controller =>"voeis/logger_imports", :action => "pre_process_logger_file_upload", :params => {:id => params[:project_id]})
          end

      end
   
    # Parses a csv file containing logger data values
    #
    # @example parse_logger_csv_header?datafile='myfilename'&start_line=3&replicate=2&column1=23&column2=24
    #
    # @param [File] datafile the csv file containing the data
    # @param [Integer] replicate a row that defines a replicate identifier
    # @param [Integer] start_line the row of the csv file that the data begins
    # @param [Integer] column/d stores the project variable id to associate with the csv column
    #
    # @return
    #
    # @author Sean Cleveland
    #
    # @api public
    def store_logger_data_from_file
      require 'chronic'  #for robust timestamp parsing
      begin #begin rescue
      data_stream =""
      timestamp_col =""
      sample_id_col = ""
      vertical_offset_col = ""
      starting_vertical_offset_col = ""
      ending_vertical_offset_col = ""
      site = parent.managed_repository{Voeis::Site.first(:id => params[:site])}
      redirect_path =Hash.new
      @source = Voeis::Source.get(params[:source])
      @project_source = nil
      parent.managed_repository do
        if Voeis::Source.first(:organization => @source.organization,      
                               :source_description => @source.source_description,
                               :source_link => @source.source_link,       
                               :contact_name => @source.contact_name,      
                               :phone => @source.phone,             
                               :email =>@source.email,             
                               :address => @source.address,           
                               :city => @source.city,              
                               :state => @source.state,             
                               :zip_code => @source.zip_code,          
                               :citation => @source.citation,          
                               :metadata_id =>@source.metadata_id).nil?       
           @project_source = Voeis::Source.create(@source.attributes)
         else
           @project_source = Voeis::Source.first(:organization => @source.organization,      
                                   :source_description => @source.source_description,
                                   :source_link => @source.source_link,       
                                   :contact_name => @source.contact_name,      
                                   :phone => @source.phone,             
                                   :email =>@source.email,             
                                   :address => @source.address,           
                                   :city => @source.city,              
                                   :state => @source.state,             
                                   :zip_code => @source.zip_code,          
                                   :citation => @source.citation,          
                                   :metadata_id =>@source.metadata_id)
         end
      end
      #put this back in later
        #if params[:no_save] != "no"

      #create a parsing template
      #create and save new DataStream
      columns_array = Array.new
      ignore_array = Array.new
      meta_tag_array = Array.new
      min_array = Array.new
      max_array = Array.new
      difference_array = Array.new
      (1..params[:row_size].to_i).each do |i|
        columns_array[i-1]  = params["column"+i.to_s]
        ignore_array[i-1] = params["ignore"+i.to_s]
        meta_tag_array[i-1] = params["tag_column"+i.to_s]
        min_array = params["min"+i.to_s]
        max_array = params["max"+i.to_s]
        difference_array = params["difference"+i.to_s]
        if params["column"+i.to_s] == "timestamp"
          timestamp_col = i-1
        # elsif params["column"+i.to_s] == "sample_id"
        #           sample_id_col = i-1
        elsif params["column"+i.to_s] == "vertical_offset"
           vertical_offset_col = i-1
        elsif params["column"+i.to_s] == "starting_vertical_offset"
            vertical_offset_col = i-1
        elsif params["column"+i.to_s] == "ending_vertical_offset"
             ending_vertical_offset_col = i-1
        end
      end
      if !params[:DST].nil?
        utc_offset = params[:utc_offset].to_i + 1
        dst = true
      else
       utc_offset = params[:utc_offset].to_i
       dst = false
      end
      #if the timestamp is in UTC then don't apply the calculate utc_offset just use 0
      if params[:time_support] == "UTC"
        dstream_utc_offset = 0
      else
        dstream_utc_offset = utc_offset
      end
      #use this when we decide to save templates and reuse them
      if params[:save_template] == "true"
        data_stream_id = create_sample_and_data_parsing_template(params[:template_name], timestamp_col, sample_id_col, columns_array, ignore_array, site, params[:datafile], params[:start_line], params[:row_size], vertical_offset_col, ending_vertical_offset_col, meta_tag_array, dstream_utc_offset, dst, @project_source, min_array, max_array, difference_array) 
        data_stream = parent.managed_repository{Voeis::DataStream.get(data_stream_id[:data_template_id])}
      else
        data_stream = parent.managed_repository{Voeis::DataStream.get(params[:data_stream_id])}

      end
      if !data_stream.data_stream_columns.first(:name => "Timestamp").nil?
        @timestamp_col = data_stream.data_stream_columns.first(:name => "Timestamp").column_number
      else
        @timestamp_col = -1
      end
        #@sample_col = data_stream.data_stream_columns.first(:name => "SampleID").column_number


      range = params[:row_size].to_i - 1
      #store all the Variables in the managed repository
      @col_vars = Array.new
      @variables = Array.new
      (0..range).each do |i|
        if columns_array[i] != nil && columns_array[i] != "ignore" && ignore_array[i] != i && i != timestamp_col && i != sample_id_col && i != vertical_offset_col && ending_vertical_offset_col != i && meta_tag_array[i].to_i == -1
          @var = Voeis::Variable.get(columns_array[i].to_i)
          parent.managed_repository do 
            # variable = Voeis::Variable.first_or_create(
            #            :variable_code => @var.variable_code,
            #            :variable_name => @var.variable_name,
            #            :speciation =>  @var.speciation,
            #            :variable_units_id => @var.variable_units_id,
            #            :sample_medium =>  @var.sample_medium,
            #            :value_type => @var.value_type,
            #            :is_regular => @var.is_regular,
            #            :time_support => @var.time_support,
            #            :time_units_id => @var.time_units_id,
            #            :data_type => @var.data_type,
            #            :general_category => @var.general_category,
            #            :no_data_value => @var.no_data_value)
             if Voeis::Variable.get(@var.id).nil?
                variable = Voeis::Variable.new
                variable.attributes = @var.attributes
                variable.save!
              else
               variable = Voeis::Variable.get(@var.id)
              end
             @col_vars[i] = variable
             @variables << variable
           end#managed repo
         end #end if
      end  #end i loop
      #site.save
      #create csv_row array
      @results=""
      parent.managed_repository do 
         @results = Voeis::DataValue.parse_logger_csv(params[:datafile], data_stream.id, site.id, params[:start_line].to_i, nil, nil)
         
      # @csv_row = Array.new
      #       csv_temp_data = CSV.read(params[:datafile])
      #       csv_size = csv_temp_data.length
      #       csv_data = CSV.read(params[:datafile])
      # 
      #       i = params[:start_line].to_i
      #       csv_data[params[:start_line].to_i-1..-1].each do |row|
      #         @csv_row[i] = row
      #             i = i + 1
      #       end#end row loop
      #           (params[:start_line].to_i-1..csv_size.to_i).each do |row|
      #             if !@csv_row[row].nil?
      #             #create meta_tag_data
      #              row_meta_tag_array = Array.new #store the current rows MetaTagData objects for association later
      #              data_stream.data_stream_columns.all(:name=>"MetaTag").each do |col| 
      #                @mtag = col.meta_tag
      #                parent.managed_repository do
      #                  mdtag = Voeis::MetaTag.new(:name=>@mtag.name, :category=>@mtag.category)
      #                  mdtag.value = @csv_row[row][col.column_number]
      #                  mdtag.save
      #                  row_meta_tag_array << mdtag
      #                end #managed_repository
      #              end #data_stream_columns
      #             parent.managed_repository do
      #               #create sample
      #               @site = Voeis::Site.get(site.id)
      #               #calculate the correct local_offset
      #               sample_datetime = Chronic.parse(@csv_row[row][timestamp_col]).to_datetime
      #               sampletime = DateTime.civil(sample_datetime.year,sample_datetime.month,
      #                            sample_datetime.day,sample_datetime.hour,sample_datetime.min,
      #                            sample_datetime.sec, data_stream.utc_offset/24.to_f)
      # 
      #               (0..range).each do |i|
      #                 if columns_array[i] != "ignore" && sample_id_col != i && timestamp_col != i &&
      #                    columns_array[i] != nil && vertical_offset_col != i && 
      #                    ending_vertical_offset_col != i && meta_tag_array[i].to_i == -1
      # 
      #                   new_data_val = Voeis::DataValue.new(:data_value => /^[-]?[\d]+(\.?\d*)(e?|E?)(\-?|\+?)\d*$|^[-]?(\.\d+)(e?|E?)(\-?|\+?)\d*$/.match(@csv_row[row][i].to_s) ? @csv_row[row][i].to_f : -9999.0, 
      #                        :local_date_time => sampletime,
      #                        :utc_offset => utc_offset,
      #                        :observes_daylight_savings => dst,
      #                        :date_time_utc => sampletime.utc,  
      #                        :replicate => 0,
      #                        :quality_control_level=>@col_vars[i].quality_control.to_i,
      #                        :string_value =>  @csv_row[row][i].blank? ? "Empty" : @csv_row[row][i],
      #                        :vertical_offset =>  vertical_offset_col == "" ? 0.0 : @csv_row[row][vertical_offset_col].to_i,
      #                        :end_vertical_offset => ending_vertical_offset_col == "" ? nil : @csv_row[row][ending_vertical_offset_col].to_i) 
      #                   new_data_val.save
      #                   new_data_val.site = @site
      #                   # @site.data_values << new_data_val
      #                   # @site.save
      #                   new_data_val.variable << @col_vars[i]
      #                   new_data_val.source = @project_source
      #                   row_meta_tag_array.map{|mtag| new_data_val.meta_tags << mtag}  #add meta_data
      #                   new_data_val.data_streams << data_stream
      #                   new_data_val.save
      #                  end #end if
      #                 end #end i loop
      #                end #end if @csv_array.nil?
      #             end #end managed repo
      #           end #end row loop
          puts "updating the site catalog" 
           Voeis::Site.get(site.id).update_site_data_catalog_variables(@variables)
        end
          # parent.publish_his
          flash[:notice] = "File parsed and stored successfully for #{site.name}. #{@results[:total_records_saved]} data values saved and #{@results[:total_rows_parsed]} rows where parsed. "
          redirect_to project_path(params[:project_id]) and return
        rescue Exception => e  
          email_exception(e,request.env)
          flash[:error] = "Problem Parsing Logger File: "+ e.message
          redirect_to(:controller =>"voeis/logger_imports", :action => "pre_process_logger_file_upload", :params => {:id => params[:project_id]})
        end
    end# end def
    
    #columns is an array of the columns that store the variable id
     def create_sample_and_data_parsing_template(template_name, timestamp_col, sample_id_col, columns_array, ignore_array, site, datafile, start_line, row_size, vertical_offset_col, ending_vertical_offset_col, meta_tag_array, utc_offset, dst, source, min_array, max_array, difference_array)
        @data_stream = ""
        parent.managed_repository do
          @data_stream = Voeis::DataStream.create(:name => template_name.to_s,
            :description => "NA",
            :filename => datafile,
            :start_line => start_line.to_i,
            :type => "Sensor",
            :utc_offset => utc_offset,
            :source => source,
            :DST => dst)
          #Add site association to data_stream

         @data_stream.sites << site
         #@data_stream.source = source
         @data_stream.save
        end #managed_repository
        @timestamp_col = -1

        range = row_size.to_i-1
        (0..range).each do |i|
          #create the Timestamp column
          if i == timestamp_col.to_i && timestamp_col != "None"
            parent.managed_repository do
              data_stream_column = Voeis::DataStreamColumn.create(
                                    :column_number => i,
                                    :name => "Timestamp",
                                    :type =>"Timestamp",
                                    :unit => "NA",
                                    :original_var => "NA")
              data_stream_column.data_streams << @data_stream

              data_stream_column.save
            end #managed_repository
          elsif i == sample_id_col.to_i
             parent.managed_repository do
               data_stream_column = Voeis::DataStreamColumn.create(
                                     :column_number => i,
                                     :name => "SampleID",
                                     :type =>"SampleID",
                                     :unit => "NA",
                                     :original_var => "NA")
               data_stream_column.data_streams << @data_stream
               data_stream_column.save
             end #managed_repository
         elsif i == vertical_offset_col.to_i
            parent.managed_repository do
              data_stream_column = Voeis::DataStreamColumn.create(
                                    :column_number => i,
                                    :name => "VerticalOffset",
                                    :type =>"VerticalOffset",
                                    :unit => "NA",
                                    :original_var => "NA")
              data_stream_column.data_streams << @data_stream
              data_stream_column.save
            end #managed_repository
          elsif i == ending_vertical_offset_col.to_i
            parent.managed_repository do
              data_stream_column = Voeis::DataStreamColumn.create(
                                    :column_number => i,
                                    :name => "EndingVerticalOffset",
                                    :type =>"EndingVerticalOffset",
                                    :unit => "NA",
                                    :original_var => "NA")
              data_stream_column.data_streams << @data_stream
              data_stream_column.save
            end #managed_repository
          elsif  columns_array[i] == "ignore" || ignore_array[i] == i.to_s
            parent.managed_repository do
              data_stream_column = Voeis::DataStreamColumn.create(
                                    :column_number => i,
                                    :name => "Ignore",
                                    :type =>"Ignore",
                                    :unit => "NA",
                                    :original_var => "NA")
              data_stream_column.data_streams << @data_stream
              data_stream_column.save
            end #managed_repository
          elsif meta_tag_array[i].to_i != -1
            @meta_tag = Voeis::MetaTag.get(meta_tag_array[i].to_i)
            parent.managed_repository do
              mtag = Voeis::MetaTag.first_or_create(:name => @meta_tag.name, :category=>@meta_tag.category)
              data_stream_column = Voeis::DataStreamColumn.create(
                                    :column_number => i,
                                    :name => "MetaTag",
                                    :type =>"MetaTag",
                                    :unit => "NA",
                                    :original_var => "NA")
              data_stream_column.data_streams << @data_stream
              data_stream_column.meta_tag = mtag
              data_stream_column.save
            end #managed_repository
          elsif  columns_array[i] != nil || columns_array[i] != ""#create other data_stream_columns and create variables
            #puts params["column"+i.to_s]
            
            var = Voeis::Variable.get(columns_array[i].to_i)
            parent.managed_repository do
              data_stream_column = Voeis::DataStreamColumn.create(
                                    :column_number => i,
                                    :name =>         var.variable_code,
                                    :original_var => var.variable_name,
                                    :unit =>         "NA",
                                    :type =>         "NA")           
              # variable = Voeis::Variable.first_or_create(
              #             :variable_code => var.variable_code,
              #             :variable_name => var.variable_name,
              #             :speciation =>  var.speciation,
              #             :variable_units_id => var.variable_units_id,
              #             :sample_medium =>  var.sample_medium,
              #             :value_type => var.value_type,
              #             :is_regular => var.is_regular,
              #             :time_support => var.time_support,
              #             :time_units_id => var.time_units_id,
              #             :data_type => var.data_type,
              #             :general_category => var.general_category,
              #             :no_data_value => var.no_data_value)
              if Voeis::Variable.get(var.id).nil?
                 variable = Voeis::Variable.new
                 variable.attributes = var.attributes
                 variable.save!
               else
                variable = Voeis::Variable.get(var.id)
               end
              data_stream_column.variables << variable
              data_stream_column.data_streams << @data_stream
              data_stream_column.save
              sensor_type = Voeis::SensorType.create(
                            :name => variable.variable_name + ':' + variable.id.to_s + ':' + site.name,
                            :min => min_array.nil? ? nil : min_array[i].to_f,
                            :max => max_array.nil? ? nil : max_array[i].to_f,
                            :difference => difference_array.nil? ? nil : difference_array.to_f)
              #Add sites and variable associations to senor_type
              #
              sensor_type.sites << site
              sensor_type.variables <<  variable
              sensor_type.data_stream_columns << data_stream_column
              sensor_type.save
              site.variables << variable
              site.save
            end #end managed repository
          end #end if
        end #end range.each
        data_template_hash = Hash.new
        #return our Awesome new data_stream or template if you would be so kind
        data_template_hash = {:data_template_id => @data_stream.id}
     end
     
     def field_measurement
         @sites = parent.managed_repository{Voeis::Site.all}
         @variables = Voeis::Variable.all
         @var_properties = Array.new
          Voeis::Variable.properties.each do |prop|
   
            @var_properties << prop.name
          end
          @var_properties.delete_if {|x| x.to_s == "id" || x.to_s == "his_id" || x.to_s == "time_units_id" || x.to_s == "is_regular" || x.to_s == "time_support" || x.to_s == "variable_code" || x.to_s == "created_at" || x.to_s == "updated_at" || x.to_s == "updated_by" || x.to_s == "updated_comment"}
         @units = Voeis::Unit.all
     end

     def create_field_measurement
       @var = Voeis::Variable.get(params[:variable].to_i)
       units = Voeis::Unit.all
       @unit = units.first(:id => @var.variable_units_id)
       parent.managed_repository do
         d_time = DateTime.parse("#{params[:time]["stamp(1i)"]}-#{params[:time]["stamp(2i)"]}-#{params[:time]["stamp(3i)"]}T#{params[:time]["stamp(4i)"]}:#{params[:time]["stamp(5i)"]}:00#{ActiveSupport::TimeZone[params[:time][:zone]].utc_offset/(60*60)}:00")
         variable = Voeis::Variable.first_or_create(
                     :variable_code => @var.variable_code,
                     :variable_name => @var.variable_name,
                     :speciation =>  @var.speciation,
                     :variable_units_id => @var.variable_units_id,
                     :sample_medium =>  @var.sample_medium,
                     :value_type => @var.value_type,
                     :is_regular => @var.is_regular,
                     :time_support => @var.time_support,
                     :time_units_id => @var.time_units_id,
                     :data_type => @var.data_type,
                     :general_category => @var.general_category,
                     :no_data_value => @var.no_data_value)

         unit = Voeis::Unit.first_or_create(:units_name => @unit.units_name,
                                            :units_type => @unit.units_type,
                                            :units_abbreviation => @unit.units_abbreviation)
         variable.units << unit
         variable.save
         site = Voeis::Site.get(params[:site].to_i)
         #create field measurments data_stream
         data_stream = Voeis::DataStream.first_or_create(:name => "Field Measurements-"+site.code,
                                                         :filename => "NA",
                                                         :start_line => -1,
                                                         :type => "Field Measurements")
         data_stream_column = Voeis::DataStreamColumn.first_or_create(:name => "FieldMeasurementColumn_"+variable.variable_code+'_'+site.code , 
                                                                      :type => "Na", 
                                                                      :unit => variable.units.first.units_name,  
                                                                      :original_var => variable.variable_name, 
                                                                      :column_number => -1)
         sensor_type = Voeis::SensorType.first_or_create(:name => "FieldMeasurement_"+variable.variable_code)
         sensor_value = Voeis::SensorValue.new(:value => params[:sensor_value].to_f,
                                                  :string_value => params[:sensor_value],
                                                  :units => variable.units.first.units_name,    
                                                  :timestamp => d_time,  
                                                  :vertical_offset => params[:vertical_offset])
         sensor_value.save
         sensor_type.sensor_values << sensor_value
         sensor_type.variables << variable
         sensor_type.save
         data_stream_column.sensor_types << sensor_type
         data_stream_column.save
         data_stream.data_stream_columns << data_stream_column
         data_stream.save
         site.data_streams << data_stream
         site.save
       end
       flash[:notice] = "Field Measurement was saved successfully."
       redirect_to new_field_measurement_project_sensor_values_path
     end
end