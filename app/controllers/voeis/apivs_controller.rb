class Voeis::ApivsController < Voeis::BaseController
  
  # Properly override defaults to ensure proper controller behavior
  # @see Voeis::BaseController
  defaults  :route_collection_name => 'apivs',
            :route_instance_name => 'apiv',
            :collection_name => 'apivs',
            :instance_name => 'apiv',
            :resource_class => Voeis::Apiv



  def format_response(data_obj, format)
    format.json do
      render :json => data_obj.as_json, :callback => params[:jsoncallback]
    end
    format.xml do
      render :xml => data_obj.to_xml
    end
    format.csv do
      render :text => data_obj.to_csv.to_s.gsub(/\n\n/, "\n")
    end
  end

  #*************DataStreams



  # pulls data from a data stream
  #
  # @example http://voeis.msu.montana.edu/projects/fbf20340-af15-11df-80e4-002500d43ea0/apivs/get_data_stream_data.json?api_key=d7ef0f4fe901e5dfd136c23a4ddb33303da104ee1903929cf3c1d9bd271ed1a7&data_stream_id=1&start_datetime=12/1/2010 12:23&end_datetime=12/1/2010 24:00:00
  #
  #
  # @param [Integer] :data_stream_id
  # @param [DateTime] :start_datetime pull data after this datetime
  # @param [DateTime] :end_datetime pull date before this datetime
  # @param [Boolean] :small_data if true this will return only local_date_time and the data_values
  #
  #
  # @author Sean Cleveland
  #
  # @api public
  def get_data_stream_data    
   @dts = ""
   @data_stream_values = Hash.new
   @values = Array.new
   parent.managed_repository do
     @dts= Voeis::DataStream.get(params[:data_stream_id].to_i)
     if @dts.nil?
       @data_stream_values[:error] = "There is no Data Stream with ID:"+params[:data_stream_id]
     elsif params[:start_datetime].nil? || params[:end_datetime].nil?
       @data_stream_values[:error] = "The start and end times must not be null"
     else
       @data_stream_values[:data_stream] = @dts.as_json
       @site = @dts.sites.first
       @dts.data_stream_columns.sensor_types.each do |sensor|
         @var_hash = Hash.new
         @var_hash = sensor.variables.first.as_json
         if params[:small_data] == 'true'
           sql = "SELECT local_date_time, data_value FROM  voeis_data_values WHERE site_id=#{@site.id} AND variable_id=#{sensor.variables.first.id} AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
           @var_hash = @var_hash.merge({'data' =>repository.adapter.select(sql)})
           @values << @var_hash
         else
           @var_hash = @var_hash.merge({'data' => sensor.sensor_values.all(:timestamp.gte => params[:start_datetime].to_time, :timestamp.lte => params[:end_datetime].to_time)})
           @values << @var_hash
         end
       end
       @data_stream_values[:variables] = @values
     end
   end
   respond_to do |format|
     format_response(@data_stream_values, format)
   end
  end
  
  
   #  @data_stream_values = Hash.new
   #   parent.managed_repository do
   #     @data_stream = Voeis::DataStream.get(params[:data_stream_id].to_i)
   #     @data_stream.data_stream_columns.sensor_types.each do |sensor|
   #     #  @data_stream_values[sensor.variables.first.variable_name] = sensor.sensor_values.all(:timestamp.gte => params[:start_datetime].to_time, :timestamp.lte => params[:end_datetime].to_time)
   #       debugger
   #     #end
   #   end
   #   respond_to do |format|//home/rochellec/GPS
   #      format.json do
   #        render :json => @data_stream_values.to_json, :callback => params[:jsoncallback]
   #      end
   #   #   format.xml do
   #   #     render :xml => @data_stream_values.to_xml
   #   #   end
   #   end
   #   
   # end
  #
  #curl -F datafile=@highland-test.csv	 -F data_template_id=10 https://voeis.msu.montana.edu/projects/e2f8e892-1f57-11e0-bbd7-6e9ffb75bc80/apivs/upload_logger_data.json?api_key=e6af8ec25873c1092596e235082e7758ae4cfe6e11e689c5150aa995a4fc89e9
  #curl -F datafile=@CR1000_BigSky_SFork.dat	 -F data_template_id=9 https://voeis.msu.montana.edu/projects/b6db01d0-e606-11df-863f-6e9ffb75bc80/apivs/upload_logger_data.json?api_key=e79b135dcfeb6699bbaa6c9ba9c1d0fc474d7adb755fa215446c398cae057adf
   
  #curl -F datafile=@CR1000_2_BigSky_NFork.csv	 -F data_template_id=2 http://localhost:3000/projects/cfee5aec-c520-11e0-a45c-c82a14fffebf/apivs/upload_logger_data.json?api_key=e79b135dcfeb6699bbaa6c9ba9c1d0fc474d7adb755fa215446c398cae057adf
  # curl -F datafile=@matt1item.csv -F data_template_id=19 -F start_line=1 -F  api_key=e79b135dcfeb6699bbaa6c9ba9c1d0fc474d7adb755fa215446c398cae057adf http://voeis.msu.montana.edu/projects/b6db01d0-e606-11df-863f-6e9ffb75bc80/apivs/upload_logger_data.json?
  # curl -F datafile=@YB_Hill.csv -F data_template_id=26 http://voeis.msu.montana.edu/projects/a459c38c-f288-11df-b176-6e9ffb75bc80/apivs/upload_logger_data.json?api_key=3b62ef7eda48955abc77a7647b4874e543edd7ffc2bb672a40215c8da51f6d09
  
  # 3b62ef7eda48955abc77a7647b4874e543edd7ffc2bb672a40215c8da51f6d09
  # 
  # curl -F datafile=@Next100-sean.csv -F data_template_id=22 -F api_key=3b62ef7eda48955abc77a7647b4874e543edd7ffc2bb672a40215c8da51f6d09 http://voeis.msu.montana.edu/projects/a459c38c-f288-11df-b176-6e9ffb75bc80/apivs/upload_logger_data.json?
  # 
  # curl -F datafile=@CR1000_BigSky_Weather_small.dat -F data_template_id=13 -F site_id=19 http://localhost:3000/projects/b6db01d0-e606-11df-863f-6e9ffb75bc80/apivs/upload_data?api_key=e79b135dcfeb6699bbaa6c9ba9c1d0fc474d7adb755fa215446c398cae057adf
  
  # curl -F datafile=@CR1000_BigSky_Weather_small.dat -F data_template_id=1 http://voeis.msu.montana.edu/projects/a4c62666-f26b-11df-b8fe-002500d43ea0/apivs/upload_logger_data?api_key=2ac150bed4cfa21320d6f37cc6f007b807c603b6c8c33b6ba5a7db92ca821f35
  
  # alows user to upload csv file to be processed into data
  # this requires that a datastream has already been created
  # to parse this file.  Can return json or xml as specified
  #
  # @example curl -F site_id=15 -F queue=true -F datafile=@CR1000_2_BigSky_NFork_smallp2.csv -F data_template_id=31 http://localhost:3000/projects/cfee5aec-c520-11e0-a45c-c82a14fffebf/apivs/upload_data.json?api_key=e79b135dcfeb6699bbaa6c9ba9c1d0fc474d7adb755fa215446c398cae057adf
  #
  #
  # @param [File] :datafile csv file to store
  # @param [Integer] :data_template_id the id of the data stream used to parse a file
  # @param [Integer] :start_line the line which your data begins (if this is not specified the data-templates starting line will be used)
  #
  # @return [String] :success or :error message
  # @return [Integer] :total_records_saved - the total number of records saved to Voeis
  # @return [Integer] :total_rows_parsed - the total number of rows successfully parsed
  # @return [String] :last_record  - the last record saved for the last variable in the row defined by the data-template - this will return the most recently created record
  # @return[String]:last_record_for_this_field - this is the last record stored for this file- if the file has already been stored this field will have a message indicating that has occurred.
  #
  # @author Sean Cleveland
  #
  # @api public
  def upload_logger_data 
    parent.managed_repository do
        first_row = Array.new
        flash_error = Hash.new
        @msg = "There was a problem parsing this file."
        name = Time.now.to_s + params[:datafile].original_filename 
        directory = "temp_data"
        @new_file = File.join(directory,name)
        File.open(@new_file, "wb"){ |f| f.write(params['datafile'].read)}
        begin 
            data_stream_template = Voeis::DataStream.get(params[:data_template_id].to_i)
            if params[:start_line].nil?
              start_line = data_stream_template.start_line
            else
              start_line = params[:start_line].to_i
            end
            if data_stream_template.utc_offset.nil?
              site = data_stream_template.sites.first
              if site.time_zone_offset.nil? || site.time_zone_offset == "unknown"
                begin
                  site.fetch_time_zone_offset
                rescue
                  #do nothing
                end
              end
              data_stream_template.utc_offset = site.time_zone_offset
              data_stream_template.save!
            end
            lines =0
            CSV.foreach(@new_file){|row| lines +=1}
            # File.open(@new_file, 'r') do |file|
            #               file.each_line do |line|
            #                 lines +=1
            #               end
            #             end
            if lines < start_line
              @msg = @msg + " Your start_line: #{start_line} for file parsing is beyond the end of the file."
            end
            csv = CSV.open(@new_file, "r")
            (1..start_line).each do
              first_row = csv.readline
            end
            csv.close()
            path = File.dirname(@new_file)
          if first_row.count == data_stream_template.data_stream_columns.count
            unless params[:queue] == "true"
              user = nil
              repository("default") do
                user = current_user
              end
              flash_error = flash_error.merge(parent.managed_repository{Voeis::DataValue.parse_logger_csv(@new_file, data_stream_template.id, data_stream_template.sites.first.id, start_line,nil,nil,user.id)})
            else
              
              puts "***********ADDING DELAYED JOB******************"
              dj = nil
              req = Hash.new
              req[:url]= request.url
              req[:ip_address] = request.remote_ip
              req [:parameters] = request.filtered_parameters.as_json
              job = Voeis::Job.create(:job_type=>"File Upload", :job_parameters=>req.to_json, :status => "queued", :submitted_at=>Time.now, :user_id => current_user.id)
              repository("default") do
                dj = Delayed::Job.enqueue(ProcessAFile.new(parent, @new_file, data_stream_template.id, data_stream_template.sites.first.id, start_line,nil,nil,current_user, job.id))
              end
              job.delayed_job_id = dj.id
              job.save
              puts dj.attributes
              puts dj.repository.name
              flash_error[:job_queue_id] = job.id
              flash_error[:success] = "File has been successfully queued.  Check the job queue for status and you will recieve and email when the job completes."
            end
          else
            #the file does not match the data_templates number of columns
            flash_error[:error] = "File does not match the data_templates number of columns. Columns in First Row:" + first_row.count.to_s +  " Voeis expected:" + data_stream_template.data_stream_columns.count.to_s + " rows."
            logger.info {"File does not match the data_templates number of columns."}
          end
        rescue   Exception => e
            email_exception(e,request.env)
            logger.info {e.to_s}
          #problem parsing file - run the data catalog to update things
          data_stream_template.sites.first.update_site_data_catalog
          flash_error[:error] = @msg + e.message
          logger.info {@msg}
        end
      #parent.publish_his
      respond_to do |format|
        if params.has_key?(:api_key)
          format.json
        end
        if flash_error[:error].nil?
          if flash_error[:success].nil?
            flash_error[:success] = "File was parsed succesfully."
          end
          data_stream_template.sites.first.update_site_data_catalog
          #flash_error = flash_error.merge({:last_record => data_stream_template.data_stream_columns.sensor_types.sensor_values.last(:order =>[:id.asc]).as_json}) 
        end
        format.json do
          render :json => flash_error.to_json, :callback => params[:jsoncallback]
        end
        format.xml do
          render :xml => flash_error.to_xml
        end
      end
    end
  end
  
  
  
  
  # alows user to upload csv file to be processed into data
  # this requires that a site and a datastream has already been created
  # to parse this file.  Can return json or xml as specified
  #
  # @example curl -F datafile=@CR1000_2_BigSky_NFork_small.dat -F data_template_id=1 -F site_id=1 http://voeis.msu.montana.edu/projects/fbf20340-af15-11df-80e4-002500d43ea0/apivs/upload_data.json?api_key=e79b135dcfeb6699bbaa6c9ba9c1d0fc474d7adb755fa215446c398cae057adf
  #
  #
  # @param [File] :datafile csv file to store
  # @param [Integer] :data_template_id the id of the data stream used to parse a file
  # @param [Integer] :site_id
  # @param [Integer] :start_line the line which your data begins (if this is not specified the data-templates starting line will be used)
  # @param [Boolean] :queue, setting this parameter to true will queue the upload job for processing later - this is recommended for large files.  
  #
  # @return [JSON Object] :success or :error message, if queue is set to true a job_queue_id will be returned
  # @return [Integer] :total_records_saved - the total number of records saved to Voeis
  # @return [Integer] :total_rows_parsed - the total number of rows successfully parsed
  # @return [String] :last_record  - the last record saved for the last variable in the row defined by the data-template - this will return the most recently created record
  # @return[String]:last_record_for_this_field - this is the last record stored for this file- if the file has already been stored this field will have a message indicating that has occurred.
  #
  # @author Sean Cleveland
  #
  # @api public
  def upload_data 
    flash_error = Hash.new
    parent.managed_repository do
      unless params[:site_id].nil?
        site = Voeis::Site.get(params[:site_id].to_i)  
        unless site.nil?
          unless params[:data_template_id].nil?
            first_row = Array.new
            
          debugger
            @msg = "There was a problem parsing this file."
            name = Time.now.to_s + params[:datafile].original_filename 
            directory = "temp_data"
            @new_file = File.join(directory,name)
            File.open(@new_file, "wb"){ |f| f.write(params['datafile'].read)}
            begin 
                data_stream_template = Voeis::DataStream.get(params[:data_template_id].to_i)
                data_stream_template.data_stream_columns.each do |dc|
                  unless dc.variables.empty?
                    site.variables << dc.variables.first
                    site.save
                  end
                end
                if params[:start_line].nil?
                  start_line = data_stream_template.start_line
                else
                  start_line = params[:start_line].to_i
                end
                if data_stream_template.utc_offset.nil?
                  if site.time_zone_offset.nil? || site.time_zone_offset == "unknown"
                    begin
                      site.fetch_time_zone_offset
                    rescue
                      #do nothing
                    end
                  end
                  data_stream_template.utc_offset = site.time_zone_offset
                  data_stream_template.save!
                end
                lines =0
                CSV.foreach(@new_file){|row| lines +=1}
                if lines < start_line
                  @msg = @msg + " Your start_line: #{start_line} for file parsing is beyond the end of the file."
                end
                csv = CSV.open(@new_file, "r")
                (1..start_line).each do
                  first_row = csv.readline
                end
                csv.close()
                path = File.dirname(@new_file)
              user = nil
              repository("default") do
                user = current_user
              end
              if first_row.count == data_stream_template.data_stream_columns.count
                unless params[:queue] == "true"
                  flash_error = flash_error.merge(parent.managed_repository{Voeis::DataValue.parse_logger_csv(@new_file, data_stream_template.id, site.id, start_line,nil,nil,user.id)})
                else
                  puts "***********ADDING DELAYED JOB******************"
                  dj = nil
                  req = Hash.new
                  req[:url]= request.url
                  req[:ip_address] = request.remote_ip
                  req [:parameters] = request.filtered_parameters.as_json
                  job = Voeis::Job.create(:job_type=>"File Upload", :job_parameters=>req.to_json, :status => "queued", :submitted_at=>Time.now, :user_id => current_user.id)
                  repository("default") do
                    dj = Delayed::Job.enqueue(ProcessAFile.new(parent, @new_file, data_stream_template.id, site.id, start_line,nil,nil,current_user, job.id))
                  end
                  job.delayed_job_id = dj.id
                  job.save
                  puts dj.attributes
                  puts dj.repository.name
                  flash_error[:job_queue_id] = job.id
                  flash_error[:success] = "File has been successfully queued.  Check the job queue for status and you will recieve and email when the job completes."
                end
              else
                #the file does not match the data_templates number of columns
                flash_error[:error] = "File does not match the data_templates number of columns. Columns in First Row:" + first_row.count.to_s +  " Voeis expected:" + data_stream_template.data_stream_columns.count.to_s + " rows."
                logger.info {"File does not match the data_templates number of columns."}
              end
            rescue   Exception => e
                email_exception(e,request.env)
                logger.info {e}
                logger.info {e.to_s}
              #problem parsing file
              site.update_site_data_catalog
              flash_error[:error] = @msg + e.message
              logger.info {@msg}
            end
          else
            flash_error[:error] = "The data_template_id can not be blank!"
          end
        else
          flash_error[:error] = "The site_id: #{params[:site_id]} does not exist in this project"
        end
      else
        flash_error[:error] = "The site_id can not be blank!"
      end
      #parent.publish_his
      respond_to do |format|
        if params.has_key?(:api_key)
          format.json
        end
        if flash_error[:error].nil?
          if flash_error[:success].nil?
            flash_error[:success] = "File was parsed succesfully."
          end
          site.update_site_data_catalog
          #flash_error = flash_error.merge({:last_record => data_stream_template.data_stream_columns.sensor_types.sensor_values.last(:order =>[:id.asc]).as_json}) 
        end
        format.json do
          render :json => flash_error.to_json, :callback => params[:jsoncallback]
        end
        format.xml do
          render :xml => flash_error.to_xml
        end
      end
    end
  end
  
  # get_job_status
  # API for getting the status of a job within a project
  #
  # @example http://voeis.msu.montana.edu/projects/e787bee8-e3ab-11df-b985-002500d43ea0/apivs/get_job_status.json?job_id = 1
  #
  # @param [Integer] :job_id
  #
  # @author Sean Cleveland
  #
  # @return [JSON String] a JSON object with the job object including status, completed_time, submitted_at, results, job_type and user_id
  # 
  # @api public
  def get_job_status
    @job = nil
    unless params[:job_id].nil?
      parent.managed_repository do
        if job = Voeis::Job.get(params[:job_id].to_i)
          job.check_status
          @job = job.attributes
        else
          @job[:errors] = "There is no job with id = #{params[:job_id]}"
        end
      end
    else
      @job[:errors] = "A job_id parameter is required!"
    end
    respond_to do |format|
     format_response(@job, format)
    end
  end
  
  # get_project_jobs
  # API for getting the jobs within a project -either all or by job status
  #
  # @example http://voeis.msu.montana.edu/projects/e787bee8-e3ab-11df-b985-002500d43ea0/apivs/get_job_status.json?job_id = 1
  #
  # @params[String] :job_status [queued, running, complete, failed, canceled] leaving this blank will fetch all jobs
  #
  # @author Sean Cleveland
  #
  # @return [JSON String] a JSON object with the job object including status, completed_time, submitted_at, results, job_type and user_id
  # 
  # @api public
  def get_project_jobs
    @jobs = Hash.new
    unless params[:job_status].nil?
      if ['queued', 'running', 'complete','failed','canceled'].include? params[:job_status]
        @jobs[:jobs] =  parent.managed_repository{Voeis::Job.all(:status=>params[:job_status])}.as_json
      else
        @jobs[:error] = "The Status: #{params[:job_status]} is not a valid option.  Please use: queued,running, complete, failed, or canceled.}"
      end
    else
      @jobs = parent.managed_repository{Voeis::Job.all}
    end
    respond_to do |format|
     format_response(@jobs, format)
    end
  end
  
  # get_project_data_summary
  # API for getting a list of the data within a Project
  #
  # @example http://voeis.msu.montana.edu/projects/e787bee8-e3ab-11df-b985-002500d43ea0/apivs/get_project_data_summary.json?
  #
  #
  # @author Sean Cleveland
  #
  # @return [JSON String] a JSON object with and array of sites and each sites variables meta-information along with the "record_number"(total number of records for the object), "starting_timestamp"(the first timestamp for a time-series related to that object) and "ending_timestamp"(the last timestamp for a time-series related to that object) for each variable, site and the project itself.
  # 
  # @api public
  def get_project_data_summary
    @summary = Hash.new
     parent.managed_repository do
       site_array = Array.new
       Voeis::Site.all.each do |site|
         #site_hash[site.id.to_s]   
         var_hash = Hash.new
         var_hash[:variables] = Array.new
         site.variables.each do |var|
           sdc = Voeis::SiteDataCatalog.first(:site_id => site.id, :variable_id => var.id)
           unless sdc.nil?
              var_hash[:variables] << var.to_hash.merge({:record_number => sdc.record_number, :starting_timestamp => sdc.starting_timestamp, :ending_timestamp => sdc.ending_timestamp})
           end
         end
         site_total = 0
         site_start = nil
         site_end = nil
         unless Voeis::SiteDataCatalog.all(:site_id => site.id).empty?
           site_start =  Voeis::SiteDataCatalog.first(:site_id => site.id,:order => [:starting_timestamp], :starting_timestamp.not => nil).nil? ? nil : Voeis::SiteDataCatalog.first(:site_id => site.id,:order => [:starting_timestamp], :starting_timestamp.not => nil).starting_timestamp
           site_end = Voeis::SiteDataCatalog.last(:site_id => site.id,:order => [:ending_timestamp], :ending_timestamp.not => nil).nil? ? nil : Voeis::SiteDataCatalog.last(:site_id => site.id,:order => [:ending_timestamp], :ending_timestamp.not => nil).ending_timestamp
           site_total = Voeis::SiteDataCatalog.sum(:record_number, :site_id => site.id)
         end
         site_array << site.to_hash.merge(var_hash).merge(:record_number => site_total, :starting_timestamp => site_start, :ending_timestamp => site_end)
       end
       @summary[:sites] = site_array
       @summary[:record_number] =Voeis::SiteDataCatalog.sum(:record_number)
       @summary[:starting_timestamp] =Voeis::SiteDataCatalog.first(:order => [:starting_timestamp], :starting_timestamp.not => nil).starting_timestamp
       @summary[:ending_timestamp] = Voeis::SiteDataCatalog.last(:order => [:ending_timestamp], :ending_timestamp.not => nil).ending_timestamp
     end
     respond_to do |format|
       format_response(@summary, format)
     end
  end
  
  # get_project_data_templates
  # API for getting a list of the data_templates within a Project
  #
  # @example http://voeis.msu.montana.edu/projects/e787bee8-e3ab-11df-b985-002500d43ea0/apivs/get_project_data_templates.json?
  #
  # @param [String] id the id of the site within the project
  #
  # @author Sean Cleveland
  #
  # @return [JSON String] an array of data_templates that exist for the project and each ones properties and values
  # 
  # @api public
  def get_project_data_templates
   @dts = ""
   parent.managed_repository do
     @dts= Voeis::DataStream.all
   end
   respond_to do |format|
     format_response(@dts, format)
   end
  end
  
  
  
   # http://voeis.msu.montana.edu/projects/b6db01d0-e606-11df-863f-6e9ffb75bc80/apivs/create_project_data_stream.json?
   # "name=mytest&start_line=1&site_id=1&api_key=d7ef0f4fe901e5dfd136c23a4ddb33303da104ee1903929cf3c1d9bd271ed1a7"
   
   
  # create_project_data_stream
  # API for creating a new data stream within a Project
  #
  # @example http://voeis.msu.montana.edu/projects/e787bee8-e3ab-11df-b985-002500d43ea0/apivs/create_project_data_stream.json?
  #
  # @param [String] name the name of the data stream 
  # @param [Integer] start_line then line in the file the data begins on
  # @param [Integer] site_id the id of the project site to associate with this data_stream
  #
  # @author Sean Cleveland
  #
  # @return [JSON String] an array of data_templates that exist for the project and each ones properties and values
  # 
  # @api public
  def create_project_data_stream
    @stream = ""
    parent.managed_repository do
      @stream = Voeis::DataStream.first_or_create(
        :name => params[:name], 
        :start_line => params[:start_line], 
        :filename => "NA")
      @stream.sites << Voeis::Site.get(params[:site_id])
      @stream.save
    end
    respond_to do |format|
     format_response(@stream, format)
    end
  end
  
  
  # http://voeis.msu.montana.edu/projects/b6db01d0-e606-11df-863f-6e9ffb75bc80/apivs/create_project_data_stream_column.json?
   # "name=mytestcol&column_number=1&type="Legacy"&unit="None"&original_var="Whatever"&variable_id=20&data_stream_id=8&api_key=d7ef0f4fe901e5dfd136c23a4ddb33303da104ee1903929cf3c1d9bd271ed1a7"
  
  
  # create_project_data_stream_column
  # API for creating a new data_stream_column within a Project
  #
  # @example http://voeis.msu.montana.edu/projects/e787bee8-e3ab-11df-b985-002500d43ea0/apivs/create_project_data_stream_column.json?
  #
  # @param [String] name the name of the data stream column - header name usually
  # @param [Integer] column_number the column number to parse with this data_stream_column object
  # @param [String] type the type of data_stream_column i.e. ("Legacy, Sensor") - optional
  # @param [String] unit the name of the unit - optional
  # @param [String] original_var the name of original headers variable name - optional
  # @param [Integer] variable_id the id of the project variable to associate with this data_stream_column
  # @param[Integer] data_stream_id the id of the data_stream to associate this data_stream_column with
  #
  # @author Sean Cleveland
  #
  # @return [JSON String] an array of data_templates that exist for the project and each ones properties and values
  # 
  # @api public
  def create_project_data_stream_column
     @data_column = ""
      parent.managed_repository do
        @data_column = Voeis::DataStreamColumn.create(
          :column_number => params[:column_number],
          :name => params[:name],
          :type => params[:type],
          :unit => params[:unit],
          :original_var => params[:original_var])
        @data_column.data_streams << Voeis::DataStream.get(params[:data_stream_id])
        @data_column.variables << Voeis::Variable.get(params[:variable_id])
        @data_column.save!
      end
      respond_to do |format|
       format_response(@data_column, format)
      end
  end
  
  def get_project_data_stream_data
    @data_values =""
    parent.managed_repository do
      data_stream = Voeis::DataStream.get(params[:data_stream_id])
      @data_values=data_stream.data_values
    end
    respond_to do |format|
     format_response(@data_values, format)
    end
  end
  # http://voeis.msu.montana.edu/projects/b6db01d0-e606-11df-863f-6e9ffb75bc80/apivs/create_project_sensor_type.json?
   # "name=mytest_sensor&min=0&max=0&differece=0&data_stream_column_id=92&variable_id=20&api_key=d7ef0f4fe901e5dfd136c23a4ddb33303da104ee1903929cf3c1d9bd271ed1a7"
  
  
  # create_project_sensor_type
  # API for creating a sensor_type within a Project
  #
  # @example http://voeis.msu.montana.edu/projects/e787bee8-e3ab-11df-b985-002500d43ea0/apivs/create_project_sensor_type.json?
  #
  # @param [String] name the name of the data stream 
  # @param [Integer] min the minimum sensor should read if working correctly
  # @param [Integer] max the maximum a sensor should read if working correctly
  # @param [Integer] difference the most one reading should differ from the last
  # @param [Integer] data_stream_column_id the data_stream_column to associate with this sensor_type
  # @param [Integer] variable_id the id of the project variable to associate with this data_stream_column
  #
  # @author Sean Cleveland
  #
  # @return [JSON String] an array of data_templates that exist for the project and each ones properties and values
  # 
  # @api public
  def create_project_sensor_type
    @sensor_type = ""
    parent.managed_repository do
      @sensor_type = Voeis::SensorType.create(
                    :name => params[:name],
                    :min => params[:min],
                    :max => params[:max],
                    :difference => params[:difference])
      #Add sites and variable associations to senor_type
      data_column = Voeis::DataStreamColumn.get(params[:data_stream_column_id])
      project_site = data_column.data_streams.first.sites.first
      project_var = Voeis::Variable.get(params[:variable_id])
      @sensor_type.sites << project_site
      @sensor_type.variables <<  project_var
      @sensor_type.data_stream_columns << data_column
      @sensor_type.save!
      project_site.variables << project_var
      project_site.save!
    end
    respond_to do |format|
     format_response(@sensor_type, format)
    end
  end
  
  #************Sensor Values
  
  # http://voeis.msu.montana.edu/projects/b6db01d0-e606-11df-863f-6e9ffb75bc80/apivs/create_project_sensor_value.json?
   # "value=23.2&unit=Whatever&timestamp=Sat Nov 20 13:54:18 -0700 2010&published=false&sensor_type_id=61&api_key=d7ef0f4fe901e5dfd136c23a4ddb33303da104ee1903929cf3c1d9bd271ed1a7"
  
  # create_project_sensor_value
  # API for creating a sensor_value within a Project
  #
  # @example http://voeis.msu.montana.edu/projects/e787bee8-e3ab-11df-b985-002500d43ea0/apivs/create_project_sensor_value.json?
  #
  # @param [Float] value the value of the sensor measurement
  # @param [String] unit the name of the units
  # @param [Timestamp] timestamp the timestamp the sensor measurement was taken at
  # @param [Float] vertical_offset - the offset from the sites offset (by default is 0.0)
  # @param [Boolean] published - true if this sensor measurement has been published to the HIS server
  # @param [Integer] sensor_type_id the sensor_type to associate this sensor_value with
  #
  # @author Sean Cleveland
  #
  # @return [JSON String] an array of data_templates that exist for the project and each ones properties and values
  # 
  # @api public
  def create_project_sensor_value
    @sensor_type = ""
    @sensor_value = 
    parent.managed_repository do
      @sensor_type = Voeis::SensorType.get(params[:sensor_type_id])
      @sensor_value = Voeis::SensorValue.create(
        :value => params[:value].to_f,
        :units => params[:unit],
        :timestamp => params[:timestamp],
        :vertical_offset => params[:vertical_offset].to_f,
        :published => params[:published],
        :string_value => params[:value])
      @sensor_value.sensor_type << @sensor_type
      @sensor_value.site << @sensor_type.sites.first
      @sensor_value.variables << @sensor_type.variables.first
      @sensor_value.save!
    end
    respond_to do |format|
     format_response(@sensor_value, format)
    end
  end
  
  
  #************Sites
  
  # pulls data from a within a project's site
  #
  # @example http://voeis.msu.montana.edu/projects/fbf20340-af15-11df-80e4-002500d43ea0/apivs/get_project_site_data.json?api_key=d7ef0f4fe901e5dfd136c23a4ddb33303da104ee1903929cf3c1d9bd271ed1a7&site_id=1&start_datetime=12/1/2010 12:23&end_datetime=12/1/2010 24:00:00
  #
  #
  # @param [Integer] :site_id the id of the site to pull data for
  # @param [DateTime] :start_datetime pull data after this datetime
  # @param [DateTime] :end_datetime pull date before this datetime
  # @param [Boolean] :small_data if true this will return only local_date_time and the data_values
  #
  # @return [JSON] a JSON object with variable, site, time_series_data, time_series_count,time_series_ max, time_series_min, time_series_avg, sample_data, sample_count, sample_max, sample_min and sample_avg fields
  #
  # @author Sean Cleveland
  #
  # @api public
  def get_project_site_data    
   @site = ""
   @data_values = Hash.new
   @values = Array.new
   parent.managed_repository do
     @site= Voeis::Site.get(params[:site_id].to_i)
     if @site.nil?
        @data_values[:error] = "There is no Site with ID:"+ params[:site_id]
     else
       @site.variables. each do |var|
         @var_hash = Hash.new
         @var_hash = var.as_json
         if params[:small_data] == 'true'
           sql = "SELECT local_date_time, data_value FROM  voeis_data_values WHERE site_id=#{@site.id} AND variable_id=#{var.id} AND datatype = 'Sensor' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
           @var_hash = @var_hash.merge({'time_series' => repository.adapter.select(sql)})
           sql = "SELECT COUNT(*) FROM  voeis_data_values WHERE  variable_id=#{var.id} AND datatype = 'Sensor' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
           @var_hash = @var_hash.merge({:time_series_count => repository.adapter.select(sql)})
           sql = "SELECT MAX(data_value) FROM  voeis_data_values WHERE variable_id=#{var.id} AND datatype = 'Sensor' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
           @var_hash = @var_hash.merge({:time_series_max => repository.adapter.select(sql)})
           sql = "SELECT MIN(data_value) FROM  voeis_data_values WHERE variable_id=#{var.id} AND datatype = 'Sensor' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
           @var_hash = @var_hash.merge({:time_series_min => repository.adapter.select(sql)})
           sql = "SELECT AVG(data_value) FROM  voeis_data_values WHERE variable_id=#{var.id} AND datatype = 'Sensor' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
           @var_hash = @var_hash.merge({:time_series_avg =>repository.adapter.select(sql)})
           
           sql = "SELECT local_date_time, data_value FROM  voeis_data_values WHERE site_id=#{@site.id} AND variable_id=#{var.id} AND datatype = 'Sample' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
           @var_hash = @var_hash.merge({'sample_data' => repository.adapter.select(sql)})
           
           sql = "SELECT COUNT(*) FROM  voeis_data_values WHERE site_id=#{@site.id} AND variable_id=#{var.id} AND datatype = 'Sample' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
           @var_hash = @var_hash.merge({:sample_count => repository.adapter.select(sql)})
           sql = "SELECT MAX(data_value) FROM  voeis_data_values WHERE site_id=#{@site.id} AND variable_id=#{var.id} AND datatype = 'Sample' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
           @var_hash = @var_hash.merge({:sample_max => repository.adapter.select(sql)})
           sql = "SELECT MIN(data_value) FROM  voeis_data_values WHERE site_id=#{@site.id} AND variable_id=#{var.id} AND datatype = 'Sample' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
           @var_hash = @var_hash.merge({:sample_min => repository.adapter.select(sql)})
           sql = "SELECT AVG(data_value) FROM  voeis_data_values WHERE site_id=#{@site.id} AND variable_id=#{var.id} AND datatype = 'Sample' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
           @var_hash = @var_hash.merge({:sample_avg =>repository.adapter.select(sql)})
           
           @values << @var_hash
           @data_values[:data_values] = @values
         else
           tseries = Voeis::DataValue.all(:datatype=>"Sensor",:local_date_time.gte => params[:start_datetime].to_time, :local_date_time.lte => params[:end_datetime].to_time, :site_id => @site.id, :variable_id => var.id) 
           @var_hash = @var_hash.merge({"time_series_data" => tseries}) 
           @var_hash = @var_hash.merge({"time_series_count"=>tseries.count})
           @var_hash = @var_hash.merge({:time_series_max=>tseries.max(:data_value)})
           @var_hash = @var_hash.merge({:time_series_min=>tseries.min(:data_value)})
           @var_hash = @var_hash.merge({:time_series_avg=>tseries.avg(:data_value)}) 
           sdata = Voeis::DataValue.all(:datatype=>"Sample",:local_date_time.gte => params[:start_datetime].to_time, :local_date_time.lte => params[:end_datetime].to_time, :site_id => @site.id, :variable_id => var.id)
           @var_hash = @var_hash.merge({"sample_data" => sdata})
           @var_hash = @var_hash.merge({"sample_count"=>sdata.count})
           @var_hash = @var_hash.merge({"sample_max"=>sdata.max(:data_value)})
           @var_hash = @var_hash.merge({"sample_min"=>sdata.min(:data_value)})
           @var_hash = @var_hash.merge({"sample_avg"=>sdata.avg(:data_value) })
           @values << @var_hash
         end
       end
       @data_values[:variables] = @values
       @data_values[:site] = @site.as_json
     end
   end
   respond_to do |format|
     format_response(@data_values, format)
   end
  end
  
  # pulls data from a within a project's site
  #
  # @example http://voeis.msu.montana.edu/projects/fbf20340-af15-11df-80e4-002500d43ea0/apivs/get_project_site_sensor_data_last_update.json?api_key=d7ef0f4fe901e5dfd136c23a4ddb33303da104ee1903929cf3c1d9bd271ed1a7&site_id=1&start_datetime=12/1/2010 12:23&end_datetime=12/1/2010 24:00:00
  #
  #
  # @param [Integer] :site_id the id of the site to pull data for
  # 
  #@return [JSON] a JSON object with variable, site, data fields
  #
  # @author Sean Cleveland
  #
  # @api public
  def get_project_site_sensor_data_last_update    
   @site = ""
   @data_values = Hash.new
   @values = Array.new
   parent.managed_repository do
     @site= Voeis::Site.get(params[:site_id].to_i)
     if @site.nil?
        @data_values[:error] = "There is no Site with ID:"+ params[:site_id].to_s
     else
       @site.variables.each do |var|
         #var = sensor.variables.first
         @var_hash = Hash.new
         @var_hash = var.as_json
         @var_hash = @var_hash.merge({'data' =>  Voeis::DataValue.last(:datatype=>"Sensor",:order => [:local_date_time.asc], :site_id => @site.id, :variable_id => var.id).as_json}) 
         @values << @var_hash
       end
       @data_values[:variables] = @values
       @data_values[:site] = @site.as_json
     end
     respond_to do |format|
       format_response(@data_values, format)
     end
    end
  end
  
  # pulls data from a within a project's site for samples only
  #
  # @example http://voeis.msu.montana.edu/projects/fbf20340-af15-11df-80e4-002500d43ea0/apivs/get_project_site_sensor_data_last_update.json?api_key=d7ef0f4fe901e5dfd136c23a4ddb33303da104ee1903929cf3c1d9bd271ed1a7&site_id=1&start_datetime=12/1/2010 12:23&end_datetime=12/1/2010 24:00:00
  #
  #
  # @param [Integer] :site_id the id of the site to pull data for
  # 
  # @return [JSON] a JSON object with variables, site, data fields
  #
  # @author Sean Cleveland
  #
  # @api public
  def get_project_site_sample_data_last_update    
   @site = ""
   @data_values = Hash.new
   @values = Array.new
   parent.managed_repository do
     @site= Voeis::Site.get(params[:site_id].to_i)
     if @site.nil?
        @data_values[:error] = "There is no Site with ID:"+ params[:site_id].to_s
     else
       @site.variables.each do |var|
         #var = sensor.variables.first
         @var_hash = Hash.new
         @var_hash = var.as_json
         @var_hash = @var_hash.merge({'data' => Voeis::DataValue.all(:datatype=>"Sample",:order => [:local_date_time.asc], :site_id => @site.id, :variable_id => var.id).last.as_json}) 
         @values << @var_hash
       end
       @data_values[:variables] = @values
       @data_values[:site] = @site.as_json
     end
     respond_to do |format|
       format_response(@data_values, format)
     end
    end
  end
  
  # pulls data from a within a project's site
  #
  # @example http://voeis.msu.montana.edu/projects/fbf20340-af15-11df-80e4-002500d43ea0/apivs/get_project_site_sensor_values_by_variable.json?api_key=d7ef0f4fe901e5dfd136c23a4ddb33303da104ee1903929cf3c1d9bd271ed1a7&site_id=1&variable_id=1&start_datetime=12/1/2010 12:23&end_datetime=12/1/2010 24:00:00
  #
  #
  # @param [Integer] :site_id the id of the site to pull data for
  # @param [Integer] :variable_id the id of the variable to get sensor values for
  # @param [DateTime] :start_datetime pull data after this datetime
  # @param [DateTime] :end_datetime pull date before this datetime
  # @param [Boolean] :small_data if true this will return only local_date_time and the data_values
  #
  # @return [JSON] a JSON object with variable, site, data, count, max, min and avg fields
  #
  # @author Sean Cleveland
  #
  # @api public
  def get_project_site_sensor_values_by_variable    
   @site = ""
   @data_values = Hash.new
   @values = Array.new
   parent.managed_repository do
     @site= Voeis::Site.get(params[:site_id].to_i)
     @variable = Voeis::Variable.get(params[:variable_id].to_i)
     if @site.nil?
        @data_values[:error] = "There is no Site with ID:"+ params[:site_id].to_s
     elsif @variable.nil?
        @data_values[:error] = "There is no Variable with ID:"+ params[:variable_id].to_s
     elsif params[:start_datetime].nil? || params[:end_datetime].nil?
        @data_values[:error] = "The start and end times must not be null"
     else
       #sensors = @variable.sensor_types & @site.sensor_types
       #sensor=sensors.first
       #if sensor.nil?
      #  @data_values[:error] = "There are no Sensor Value for this site and variable combination"
      # else
      if params[:small_data] == 'true'
        sql = "SELECT local_date_time, data_value FROM  voeis_data_values WHERE site_id=#{@site.id} AND variable_id=#{@variable.id} AND datatype = 'Sensor' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
        @data_values[:data] = repository.adapter.select(sql)
        
        sql = "SELECT COUNT(*) FROM  voeis_data_values WHERE site_id=#{@site.id} AND variable_id=#{@variable.id} AND datatype = 'Sensor' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
        @data_values[:time_series_count] = repository.adapter.select(sql)
        sql = "SELECT MAX(data_value) FROM  voeis_data_values WHERE site_id=#{@site.id} AND variable_id=#{@variable.id} AND datatype = 'Sensor' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
        @data_values[:time_series_max] = repository.adapter.select(sql)
        sql = "SELECT MIN(data_value) FROM  voeis_data_values WHERE site_id=#{@site.id} AND variable_id=#{@variable.id} AND datatype = 'Sensor' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
        @data_values[:time_series_min] = repository.adapter.select(sql)
        sql = "SELECT AVG(data_value) FROM  voeis_data_values WHERE site_id=#{@site.id} AND variable_id=#{@variable.id} AND datatype = 'Sensor' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
        @data_values[:time_series_avg] =repository.adapter.select(sql)
        
      else
         @data_values[:variable] = @variable.as_json
         tseries=Voeis::DataValue.all(:datatype=>"Sensor", :local_date_time.gte => params[:start_datetime].to_time, :local_date_time.lte => params[:end_datetime].to_time, :site_id => @site.id, :variable_id => @variable.id,:order => [:local_date_time.asc]) 
         @data_values[:site] = @site.as_json
         @data_values[:data] = tseries.as_json
         @data_values[:time_series_count] = tseries.count
         @data_values[:time_series_max] = tseries.max(:data_value)
         @data_values[:time_series_min] =tseries.min(:data_value)
         @data_values[:time_series_avg]=tseries.avg(:data_value)
      end
     end
     respond_to do |format|
       format_response(@data_values, format)
     end
    end
  end
  
  
  # returns the number of data record from a within a project's site for a variable for sensor values
  #
  # @example http://voeis.msu.montana.edu/projects/fbf20340-af15-11df-80e4-002500d43ea0/apivs/get_project_site_sensor_values_count_by_variable.json?api_key=d7ef0f4fe901e5dfd136c23a4ddb33303da104ee1903929cf3c1d9bd271ed1a7&site_id=1&variable_id=1&start_datetime=12/1/2010 12:23&end_datetime=12/1/2010 24:00:00
  #
  #
  # @param [Integer] :site_id the id of the site to pull data for
  # @param [Integer] :variable_id the id of the variable to get sensor values for
  # @param [DateTime] :start_datetime pull data after this datetime
  # @param [DateTime] :end_datetime pull date before this datetime
  #
  # @return [JSON] a JSON object with variable, site, and time_series_count fields
  #
  # @author Sean Cleveland
  #
  # @api public
  def get_project_site_sensor_values_count_by_variable    
   @site = ""
   @data_values = Hash.new
   @values = Array.new
   parent.managed_repository do
     @site= Voeis::Site.get(params[:site_id].to_i)
     @variable = Voeis::Variable.get(params[:variable_id].to_i)
     if @site.nil?
        @data_values[:error] = "There is no Site with ID:"+ params[:site_id].to_s
     elsif @variable.nil?
        @data_values[:error] = "There is no Variable with ID:"+ params[:variable_id].to_s
     elsif params[:start_datetime].nil? || params[:end_datetime].nil?
        @data_values[:error] = "The start and end times must not be null"
     else   
       @data_values[:variable] = @variable.as_json
       tseries=Voeis::DataValue.all(:datatype=>"Sensor", :local_date_time.gte => params[:start_datetime].to_time, :local_date_time.lte => params[:end_datetime].to_time, :site_id => @site.id, :variable_id => @variable.id,:order => [:local_date_time.asc]).count 
       @data_values[:site] = @site.as_json
       @data_values[:time_series_count] = tseries
     end
     respond_to do |format|
       format_response(@data_values, format)
     end
    end
  end
  
  
  
  # pulls data from a within a project's site for samples only
  #
  # @example http://voeis.msu.montana.edu/projects/fbf20340-af15-11df-80e4-002500d43ea0/apivs/get_project_site_sample_values_by_variable.json?api_key=d7ef0f4fe901e5dfd136c23a4ddb33303da104ee1903929cf3c1d9bd271ed1a7&site_id=1&variable_id=7&start_datetime=12/1/2010 12:23&end_datetime=12/1/2010 24:00:00
  #
  #
  # @param [Integer] :site_id the id of the site to pull data for
  # @param [Integer] :variable_id the id of the variable to get sensor values for
  # @param [DateTime] :start_datetime pull data after this datetime
  # @param [DateTime] :end_datetime pull date before this datetime
  # @param [Boolean] :small_data if true this will return only local_date_time and the data_values
  #
  # @return [JSON] a JSON object with variable, site, data, count, max, min and avg fields
  # 
  # @author Sean Cleveland
  #
  # @api public
  def get_project_site_sample_values_by_variable    
   @site = ""
   @data_values = Hash.new
   @values = Array.new
   parent.managed_repository do
     @site= Voeis::Site.get(params[:site_id].to_i)
     @variable = Voeis::Variable.get(params[:variable_id].to_i)
     if @site.nil?
        @data_values[:error] = "There is no Site with ID:"+ params[:site_id].to_s
     elsif @variable.nil?
        @data_values[:error] = "There is no Variable with ID:"+ params[:variable_id].to_s
     elsif params[:start_datetime].nil? || params[:end_datetime].nil?
        @data_values[:error] = "The start and end times must not be null"
     else
       #sensors = @variable.sensor_types & @site.sensor_types
       #sensor=sensors.first
       #if sensor.nil?
      #  @data_values[:error] = "There are no Sensor Value for this site and variable combination"
      # else
      if params[:small_data] == 'true'
        sql = "SELECT local_date_time, data_value FROM  voeis_data_values WHERE site_id=#{@site.id} AND variable_id=#{@variable.id} AND datatype = 'Sample' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
        @data_values[:data] = repository.adapter.select(sql)
        
        sql = "SELECT COUNT(*) FROM  voeis_data_values WHERE site_id=#{@site.id} AND variable_id=#{@variable.id} AND datatype = 'Sample' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
        @data_values[:sample_count] = repository.adapter.select(sql)
        sql = "SELECT MAX(data_value) FROM  voeis_data_values WHERE site_id=#{@site.id} AND variable_id=#{@variable.id} AND datatype = 'Sample' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
        @data_values[:sample_max] = repository.adapter.select(sql)
        sql = "SELECT MIN(data_value) FROM  voeis_data_values WHERE site_id=#{@site.id} AND variable_id=#{@variable.id} AND datatype = 'Sample' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
        @data_values[:sample_min] = repository.adapter.select(sql)
        sql = "SELECT AVG(data_value) FROM  voeis_data_values WHERE site_id=#{@site.id} AND variable_id=#{@variable.id} AND datatype = 'Sample' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
        @data_values[:sample_avg] =repository.adapter.select(sql)
      else
         @data_values[:variable] = @variable.as_json
         tseries = Voeis::DataValue.all(:datatype=>"Sample",:local_date_time.gte => params[:start_datetime].to_time, :local_date_time.lte => params[:end_datetime].to_time, :site_id=>@site.id, :variable_id => @variable.id, :order => [:local_date_time.asc]) 
         @data_values[:site] = @site.as_json
         @data_values[:data] = tseries.as_json
         @data_values[:sample_count] = tseries.count
         @data_values[:sample_max] = tseries.max(:data_value)
         @data_values[:sample_min] =tseries.min(:data_value)
         @data_values[:sample_avg]=tseries.avg(:data_value)
       end
     end
     respond_to do |format|
       format_response(@data_values, format)
     end
    end
  end
  
  # returns the number of data record from a within a project's site for a variable for sample values
  #
  # @example http://voeis.msu.montana.edu/projects/fbf20340-af15-11df-80e4-002500d43ea0/apivs/get_project_site_sample_values_count_by_variable.json?api_key=d7ef0f4fe901e5dfd136c23a4ddb33303da104ee1903929cf3c1d9bd271ed1a7&site_id=1&variable_id=7&start_datetime=12/1/2010 12:23&end_datetime=12/1/2010 24:00:00
  #
  #
  # @param [Integer] :site_id the id of the site to pull data for
  # @param [Integer] :variable_id the id of the variable to get sensor values for
  # @param [DateTime] :start_datetime pull data after this datetime
  # @param [DateTime] :end_datetime pull date before this datetime
  #
  # @return [JSON] a JSON object with variable, site and data_count fields
  # 
  # @author Sean Cleveland
  #
  # @api public
  def get_project_site_sample_values_count_by_variable    
   @site = ""
   @data_values = Hash.new
   @values = Array.new
   parent.managed_repository do
     @site= Voeis::Site.get(params[:site_id].to_i)
     @variable = Voeis::Variable.get(params[:variable_id].to_i)
     if @site.nil?
        @data_values[:error] = "There is no Site with ID:"+ params[:site_id].to_s
     elsif @variable.nil?
        @data_values[:error] = "There is no Variable with ID:"+ params[:variable_id].to_s
     elsif params[:start_datetime].nil? || params[:end_datetime].nil?
        @data_values[:error] = "The start and end times must not be null"
     else
         @data_values[:variable] = @variable.as_json
         tseries = Voeis::DataValue.all(:datatype=>"Sample",:local_date_time.gte => params[:start_datetime].to_time, :local_date_time.lte => params[:end_datetime].to_time, :site_id=>@site.id, :variable_id => @variable.id, :order => [:local_date_time.asc]).count 
         @data_values[:site] = @site.as_json
         @data_values[:sample_count] = tseries
     end
     respond_to do |format|
       format_response(@data_values, format)
     end
    end
  end
  
  # create_project_site
  # API for creating a new site within in a project
  # 
  # @example http://voeis.msu.montana.edu/projects/e787bee8-e3ab-11df-b985-002500d43ea0/apivs/create_project_site.json?name=example&code=example&latitude=45.232&longitude=-111.234&state=MT 
  #
  # @param [String] name the name of the site
  # @param [String] code the unique code for identifying the site
  # @param [Float] latitude the latitude coordinate of the site
  # @param [Float] longitude the longitude coordinate for the site
  # @param [String] state the two letter abbreviation for a US state
  #  
  # @author Sean Cleveland
  #
  # @api public
  def create_project_site
    @site = ""
    parent.managed_repository do
      @site = Voeis::Site.new
      Voeis::Site.properties.each do |prop|
        if prop.name.to_s != "id"
          if !params[prop.name].nil?
            @site[prop.name.to_s] = params[prop.name.to_s]
          end #endif
        end#endif
      end#end loop
      begin
       @site.save
      rescue
       puts @site = {:errors => @site.errors}
      end
    end
    respond_to do |format|
      format_response(@site, format)
    end
  end
  
  
  # update_project_site
  # API for updating a site within in a project
  # 
  # @example http://voeis.msu.montana.edu/projects/e787bee8-e3ab-11df-b985-002500d43ea0/apivs/update_project_site.json?id=1&name=example&code=example&latitude=45.232&longitude=-111.234&state=MT 
  #
  # @param [Integer] id the id of the site
  # @param [String] name the name of the site - <optional>
  # @param [String] code the unique code for identifying the site - <optional>
  # @param [Float] latitude the latitude coordinate of the site - <optional>
  # @param [Float] longitude the longitude coordinate for the site - <optional>
  # @param [String] state the two letter abbreviation for a US state - <optional>
  #  
  # @author Sean Cleveland
  #
  # @api public
  def update_project_site
    @site = ""
    begin
      if !params['id'].empty?
        parent.managed_repository do
          @site = Voeis::Site.get(params['id'].to_i)
          Voeis::Site.properties.each do |prop|
            if prop.name.to_s != "id"
              if !params[prop.name].nil? || !params[prop.name].empty?
                @site[prop.name.to_s] = params[prop.name.to_s]
              end #endif
            end#endif
          end#end loop
          @site.save!
        end #end repo
      end #endif
    rescue Exception => e
      @site=Hash.new
      @site[:errors] = e.message
    end #end rescue
    respond_to do |format|
      format_response(@site, format)
    end
  end
  
  # get_project_site
  # API for getting a site within a Project
  #
  # @example http://voeis.msu.montana.edu/projects/e787bee8-e3ab-11df-b985-002500d43ea0/apivs/get_project_site.json?id=1
  #
  # @param [String] id the id of the site within the project
  #
  # @author Sean Cleveland
  #
  # @api public
  def get_project_site
    @site = ""
    parent.managed_repository do
      @site = Voeis::Site.get(params[:id])
    end
    respond_to do |format|
      format_response(@site, format)
    end
  end

  # get_project_sites
  # API for getting all the sites within in a project
  #
  #
  # @example http://voeis.msu.montana.edu/projects/e787bee8-e3ab-11df-b985-002500d43ea0/apivs/get_project_sites.json?
  # 
  # @author Sean Cleveland
  #
  # @api public
  def get_project_sites
    @site = ""
    parent.managed_repository do
      @site = Voeis::Site.all()
    end
    respond_to do |format|
      format_response(@site, format)
    end
  end
   
   # get_voeis_sites
   # API for getting all the sites that are public in the VOEIS system
   #
   #
   # @example http://voeis.msu.montana.edu/projects/e787bee8-e3ab-11df-b985-002500d43ea0/apivs/get_voeis_sites.json?
   # 
   # @author Sean Cleveland
   #
   # @api public
   def get_voeis_sites
     @site = ""
     @site = Voeis::Site.all()
     respond_to do |format|
       format_response(@site, format)
     end
   end
   #************Variables
   
   # pulls data from a within a project's by the variable
   #
   # @example http://voeis.msu.montana.edu/projects/fbf20340-af15-11df-80e4-002500d43ea0/apivs/get_project_variable_data.json?api_key=d7ef0f4fe901e5dfd136c23a4ddb33303da104ee1903929cf3c1d9bd271ed1a7&variable_id=1&start_datetime=12/1/2010 12:23&end_datetime=12/1/2010 24:00:00
   #
   #
   # @param [Integer] :variable_id the id of the variable to pull data for
   # @param [DateTime] :start_datetime pull data after this datetime
   # @param [DateTime] :end_datetime pull date before this datetime
   # @param [Boolean] :small_data if true this will return only local_date_time and the data_values
   #
   # @return [JSON] a JSON object with variable, site, project, time_series_count, time_series_max, time_series_min, time_series_avg, sample_count, sample_max, sample_min, sample_avg, times_series_data and sample_data fields
   # @author Sean Cleveland
   #
   # @api public
   def get_project_variable_data    
    @var = ""
    @data_values = Hash.new
    @values = Array.new
    parent.managed_repository do
      @var= Voeis::Variable.get(params[:variable_id].to_i)
      if @var.nil?
        @data_values[:error] = "There is no variable with the ID:"+params[:variable_id]
      else
        @var_hash = Hash.new
        if params[:small_data] == 'true'
          sql = "SELECT local_date_time, data_value FROM  voeis_data_values WHERE variable_id=#{@var.id} AND datatype = 'Sensor' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
          @var_hash = @var_hash.merge({'time_series' => repository.adapter.select(sql)})
          
          sql = "SELECT COUNT(*) FROM  voeis_data_values WHERE  variable_id=#{@var.id} AND datatype = 'Sensor' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
          @var_hash = @var_hash.merge({:time_series_count => repository.adapter.select(sql)})
          sql = "SELECT MAX(data_value) FROM  voeis_data_values WHERE variable_id=#{@var.id} AND datatype = 'Sensor' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
          @var_hash = @var_hash.merge({:time_series_max => repository.adapter.select(sql)})
          sql = "SELECT MIN(data_value) FROM  voeis_data_values WHERE variable_id=#{@var.id} AND datatype = 'Sensor' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
          @var_hash = @var_hash.merge({:time_series_min => repository.adapter.select(sql)})
          sql = "SELECT AVG(data_value) FROM  voeis_data_values WHERE variable_id=#{@var.id} AND datatype = 'Sensor' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
          @var_hash = @var_hash.merge({:time_series_avg =>repository.adapter.select(sql)})
          
          sql = "SELECT local_date_time, data_value FROM  voeis_data_values WHERE variable_id=#{@var.id} AND datatype = 'Sample' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
          @var_hash = @var_hash.merge({'sample_data' => repository.adapter.select(sql)})
          
          sql = "SELECT COUNT(*) FROM  voeis_data_values WHERE variable_id=#{@var.id} AND datatype = 'Sample' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
          @var_hash = @var_hash.merge({:sample_count => repository.adapter.select(sql)})
          sql = "SELECT MAX(data_value) FROM  voeis_data_values WHERE variable_id=#{@var.id} AND datatype = 'Sample' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
          @var_hash = @var_hash.merge({:sample_max => repository.adapter.select(sql)})
          sql = "SELECT MIN(data_value) FROM  voeis_data_values WHERE variable_id=#{@var.id} AND datatype = 'Sample' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
          @var_hash = @var_hash.merge({:sample_min => repository.adapter.select(sql)})
          sql = "SELECT AVG(data_value) FROM  voeis_data_values WHERE variable_id=#{@var.id} AND datatype = 'Sample' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
          @var_hash = @var_hash.merge({:sample_avg =>repository.adapter.select(sql)})
          
          @values << @var_hash
          @data_values[:data_values] = @values
        else
          @var_hash = @var.as_json
          tseries = Voeis::DataValue.all(:datatype=>"Sensor", :variable_id=> @var.id, :local_date_time.gte => params[:start_datetime].to_time, :local_date_time.lte => params[:end_datetime].to_time)
          @var_hash = @var_hash.merge({'time_series_data'=>  tseries})
          sseries = Voeis::DataValue.all(:datatype=>"Sample", :variable_id=> @var.id, :local_date_time.gte => params[:start_datetime].to_time, :local_date_time.lte => params[:end_datetime].to_time)
          @var_hash = @var_hash.merge({'sample_data' => sseries})
          @var_hash[:time_series_count] = tseries.count
          @var_hash[:time_series_max] = tseries.max(:data_value)
          @var_hash[:time_series_min] =tseries.min(:data_value)
          @var_hash[:time_series_avg]=tseries.avg(:data_value)
          @var_hash[:sample_count] = sseries.count
          @var_hash[:sample_max] = sseries.max(:data_value)
          @var_hash[:sample_min] =sseries.min(:data_value)
          @var_hash[:sample_avg]=sseries.avg(:data_value)
          @values << @var_hash
          @data_values[:variable] = @values
          @data_values[:project] = parent.as_json
        end
      end#end if
    end #end repo
    respond_to do |format|
      format_response(@data_values, format)
    end
   end 
   
   
   # pulls data from a within a project's by the variable and returns the number of records
    #
    # @example http://voeis.msu.montana.edu/projects/fbf20340-af15-11df-80e4-002500d43ea0/apivs/get_project_variable_data.json?api_key=d7ef0f4fe901e5dfd136c23a4ddb33303da104ee1903929cf3c1d9bd271ed1a7&variable_id=1&start_datetime=12/1/2010 12:23&end_datetime=12/1/2010 24:00:00
    #
    #
    # @param [Integer] :variable_id the id of the variable to pull data for
    # @param [DateTime] :start_datetime pull data after this datetime
    # @param [DateTime] :end_datetime pull date before this datetime
    #
    # @return [JSON] a JSON object with variable_object, site_object, project_object, time_series_count, and sample_count fields
    # @author Sean Cleveland
    #
    # @api public
    def get_project_variable_data_count    
     @var = ""
     @data_values = Hash.new
     @values = Array.new
     parent.managed_repository do
       @var= Voeis::Variable.get(params[:variable_id].to_i)
       if @var.nil?
         @data_values[:error] = "There is no variable with the ID:"+params[:variable_id]
       else
         @var_hash = Hash.new
         
           @var_hash = @var.as_json
           tseries = Voeis::DataValue.all(:datatype=>"Sensor", :variable_id=> @var.id, :local_date_time.gte => params[:start_datetime].to_time, :local_date_time.lte => params[:end_datetime].to_time)
           sseries = Voeis::DataValue.all(:datatype=>"Sample", :variable_id=> @var.id, :local_date_time.gte => params[:start_datetime].to_time, :local_date_time.lte => params[:end_datetime].to_time)
           @var_hash[:time_series_count] = tseries.count
           @var_hash[:sample_count] = sseries.count
           @values << @var_hash
           @data_values[:variable] = @values
           @data_values[:project] = parent.as_json
           @data_values[:time_series_count] = tseries.count
           @data_values[:sample_count] = sseries.count
       end#end if
     end #end repo
     respond_to do |format|
       format_response(@data_values, format)
     end
    end
   
   
   
   # pulls data from a within a project's by site and the variable
   #
   # @example http://voeis.msu.montana.edu/projects/fbf20340-af15-11df-80e4-002500d43ea0/apivs/get_project_site_variable_data.json?api_key=d7ef0f4fe901e5dfd136c23a4ddb33303da104ee1903929cf3c1d9bd271ed1a7&site_id=1&variable_id=1&start_datetime=12/1/2010 12:23&end_datetime=12/1/2010 24:00:00
   #
   #
   # @param [Integer] :site_id the id for site to pull data for
   # @param [Integer] :variable_id the id of the variable to pull data for
   # @param [DateTime] :start_datetime pull data after this datetime
   # @param [DateTime] :end_datetime pull date before this datetime
   # @param [Boolean] :small_data if true this will return only local_date_time and the data_values
   #
   # @return [JSON] a JSON object with variable, site, project, time_series_count, time_series_max, time_series_min, time_series_avg, sample_count, sample_max, sample_min, sample_avg, times_series_data and sample_data fields
   #
   # @author Sean Cleveland
   #
   # @api public
   def get_project_site_variable_data    
    @var = ""
    @data_values = Hash.new
    @values = Array.new
    parent.managed_repository do
      @site = Voeis::Site.get(params[:site_id].to_i)
      if @site.nil?
        @data_values[:error] = "There is no site with the ID:" + params[:site_id]
      else
        @var= Voeis::Variable.get(params[:variable_id].to_i)
        if @var.nil?
          @data_values[:error] = "There is no variable with the ID:" + params[:variable_id]
        else
          @var_hash = Hash.new
          @var_hash = @var.as_json
          if params[:small_data] == 'true'
            sql = "SELECT local_date_time, data_value FROM  voeis_data_values WHERE site_id=#{@site.id} AND variable_id=#{@var.id} AND datatype = 'Sensor' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
            @var_hash = @var_hash.merge({'time_series_data' => repository.adapter.select(sql)})
            sql = "SELECT COUNT(*) FROM  voeis_data_values WHERE site_id=#{@site.id} AND variable_id=#{@var.id} AND datatype = 'Sensor' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
            @var_hash = @var_hash.merge({:time_series_count => repository.adapter.select(sql)})
            sql = "SELECT MAX(data_value) FROM  voeis_data_values WHERE site_id=#{@site.id} AND variable_id=#{@var.id} AND datatype = 'Sensor' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
            @var_hash = @var_hash.merge({:time_series_max => repository.adapter.select(sql)})
            sql = "SELECT MIN(data_value) FROM  voeis_data_values WHERE site_id=#{@site.id} AND variable_id=#{@var.id} AND datatype = 'Sensor' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
            @var_hash = @var_hash.merge({:time_series_min => repository.adapter.select(sql)})
            sql = "SELECT AVG(data_value) FROM  voeis_data_values WHERE site_id=#{@site.id} AND variable_id=#{@var.id} AND datatype = 'Sensor' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
            @var_hash = @var_hash.merge({:time_series_avg =>repository.adapter.select(sql)})
            sql = "SELECT local_date_time, data_value FROM  voeis_data_values WHERE site_id=#{@site.id} AND variable_id=#{@var.id} AND datatype = 'Sample' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
            @var_hash = @var_hash.merge({'sample_data' => repository.adapter.select(sql)})
            sql = "SELECT COUNT(*) FROM  voeis_data_values WHERE site_id=#{@site.id} AND variable_id=#{@var.id} AND datatype = 'Sample' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
            @var_hash = @var_hash.merge({:sample_count => repository.adapter.select(sql)})
            sql = "SELECT MAX(data_value) FROM  voeis_data_values WHERE site_id=#{@site.id} AND variable_id=#{@var.id} AND datatype = 'Sample' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
            @var_hash = @var_hash.merge({:sample_max => repository.adapter.select(sql)})
            sql = "SELECT MIN(data_value) FROM  voeis_data_values WHERE site_id=#{@site.id} AND variable_id=#{@var.id} AND datatype = 'Sample' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
            @var_hash = @var_hash.merge({:sample_min => repository.adapter.select(sql)})
            sql = "SELECT AVG(data_value) FROM  voeis_data_values WHERE site_id=#{@site.id} AND variable_id=#{@var.id} AND datatype = 'Sample' AND local_date_time >= '#{params[:start_datetime].to_time}' AND local_date_time <= '#{params[:end_datetime].to_time}'"
            @var_hash = @var_hash.merge({:sample_avg =>repository.adapter.select(sql)})
            @values << @var_hash
            @data_values[:data_values] = @values
          else
            #if !@var.sensor_types.first.nil?
             
            tseries = Voeis::DataValue.all(:datatype=>"Sensor", :site_id=>@site.id, :variable_id=>@var.id, :local_date_time.gte => params[:start_datetime].to_time, :local_date_time.lte => params[:end_datetime].to_time)
            @var_hash = @var_hash.merge({'time_series_data'=> tseries})
            
            sseries = Voeis::DataValue.all(:site_id=>@site.id, :variable_id=>@var.id,:datatype=>"Sample",:local_date_time.gte => params[:start_datetime].to_time, :local_date_time.lte => params[:end_datetime].to_time)
            @var_hash = @var_hash.merge({'sample_data' => sseries})
            @var_hash[:time_series_count] = tseries.count
            @var_hash[:time_series_max] = tseries.max(:data_value)
            @var_hash[:time_series_min] =tseries.min(:data_value)
            @var_hash[:time_series_avg]=tseries.avg(:data_value)
            @var_hash[:sample_count] = sseries.count
            @var_hash[:sample_max] = sseries.max(:data_value)
            @var_hash[:sample_min] =sseries.min(:data_value)
            @var_hash[:sample_avg]=sseries.avg(:data_value)
            
              #@var_hash = @var_hash.merge({'data' => @var.data_values.all(:local_date_time.gte => params[:start_datetime].to_time, :local_date_time.lte => params[:end_datetime].to_time) & @site.data_values.all(:local_date_time.gte => params[:start_datetime].to_time, :local_date_time.lte => params[:end_datetime].to_time)})  
            @values << @var_hash
            @data_values[:variable] = @values
            @data_values[:site] = @site
            @data_values[:project] = parent.as_json

           end
        end
      end
    end
    respond_to do |format|
      format_response(@data_values, format)
    end
   end
   
    # counts the data records from a within a project's by site and the variable
    #
    # @example http://voeis.msu.montana.edu/projects/fbf20340-af15-11df-80e4-002500d43ea0/apivs/get_project_site_variable_data_count.json?api_key=d7ef0f4fe901e5dfd136c23a4ddb33303da104ee1903929cf3c1d9bd271ed1a7&site_id=1&variable_id=1&start_datetime=12/1/2010 12:23&end_datetime=12/1/2010 24:00:00
    #
    #
    # @param [Integer] :site_id the id for site to pull data for
    # @param [Integer] :variable_id the id of the variable to pull data for
    # @param [DateTime] :start_datetime pull data after this datetime
    # @param [DateTime] :end_datetime pull date before this datetime
    #
    # @return [JSON] a JSON object with variable_object, site_object, project_object, time_series_count, and sample_count fields
    #
    # @author Sean Cleveland
    #
    # @api public
    def get_project_site_variable_data_count    
     @var = ""
     @data_values = Hash.new
     @values = Array.new
     parent.managed_repository do
       @site = Voeis::Site.get(params[:site_id].to_i)
       if @site.nil?
         @data_values[:error] = "There is no site with the ID:" + params[:site_id]
       else
         @var= Voeis::Variable.get(params[:variable_id].to_i)
         if @var.nil?
           @data_values[:error] = "There is no variable with the ID:" + params[:variable_id]
         else
           @var_hash = Hash.new
           @var_hash = @var.as_json
           tseries = Voeis::DataValue.all(:datatype=>"Sensor", :site_id=>@site.id, :variable_id=>@var.id, :local_date_time.gte => params[:start_datetime].to_time, :local_date_time.lte => params[:end_datetime].to_time)
           sseries = Voeis::DataValue.all(:site_id=>@site.id, :variable_id=>@var.id,:datatype=>"Sample",:local_date_time.gte => params[:start_datetime].to_time, :local_date_time.lte => params[:end_datetime].to_time)
           @var_hash[:time_series_count] = tseries.count
           @var_hash[:sample_count] = sseries.count
           @values << @var_hash
           @data_values[:variable] = @values
           @data_values[:site] = @site
           @data_values[:time_series_count] = tseries.count
           @data_values[:sample_count] = sseries.count
           @data_values[:project] = parent.as_json
         end
       end
     end
     respond_to do |format|
       format_response(@data_values, format)
     end
    end
   
   
   # create_project_variable
   # API for creating a new variable within in a project
   # 
   # @example http://voeis.msu.montana.edu/projects/e787bee8-e3ab-11df-b985-002500d43ea0/apivs/create_project_variable.json?variable_name=example&variable_code=example&speciation=unkown&sample_medium=surface water&state=MT 
   #
   # @param [String] variable_name the name of the variable - exists in variable_names_cv
   # @param [String] variable_code the unique code for identifying this variable
   # @param [String] speciation the speciation of the vairable - may be "unknown"
   #  
   # @author Sean Cleveland
   #
   # @api public
   def create_project_variable
     @variable = ""
     parent.managed_repository do
       @variable = Voeis::Variable.new(:variable_name => params[:variable_name], 
                                      :variable_code => params[:variable_code],
                                      :speciation => params[:speciation],
                                      :sample_medium => params[:sample_medium],
                                      :value_type => params[:value_tyep],
                                      :data_type => params[:data_type])
      begin
       @variable.save
      rescue
        puts @variable = {:errors => @variable.errors}
      end
     end
     respond_to do |format|
       format_response(@variable, format)
     end
   end
   
   # get_project_variable
   # API for getting a variable within a Project
   #
   # @example http://voeis.msu.montana.edu/projects/e787bee8-e3ab-11df-b985-002500d43ea0/apivs/get_project_variable.json?id=1
   #
   # @param [String] id the id of the site within the project
   #
   # @author Sean Cleveland
   #
   # @api public
   def get_project_variable
     @variable = ""
     parent.managed_repository do
       @variable = Voeis::Variable.get(params[:id])
     end
     respond_to do |format|
       format_response(@variable, format)
     end
   end
  # get_project_variables
  # API for getting all the sites within in a project
  #
  #
  # @example http://voeis.msu.montana.edu/projects/e787bee8-e3ab-11df-b985-002500d43ea0/apivs/get_project_variables.json?
  # 
  # @author Sean Cleveland
  #
  # @api public
  def get_project_variables
    @variable = ""
    parent.managed_repository do
      @variable = Voeis::Variable.all()
    end
    respond_to do |format|
      format_response(@variable, format)
    end
  end
  
   # get_voeis_variables
   # API for getting all the variables within in the VOEIS system
   #
   #
   # @example http://voeis.msu.montana.edu/projects/e787bee8-e3ab-11df-b985-002500d43ea0/apivs/get_voeis_variables.json?
   # @example http://voeis.msu.montana.edu/projects/e787bee8-e3ab-11df-b985-002500d43ea0/apivs/get_voeis_variables.xml?
   # @author Sean Cleveland
   #
   # @api public
   def get_voeis_variables
     @variables = ""
     @variables = Voeis::Variable.all()
     respond_to do |format|
       format_response(@variables, format)
     end
   end
   
   
   # update_project_variable
   # API for creating a new variable within in a project
   # 
   # @example http://voeis.msu.montana.edu/projects/e787bee8-e3ab-11df-b985-002500d43ea0/apivs/create_project_variable.json?variable_name=example&variable_code=example&speciation=unkown&sample_medium=surface water&state=MT 
   #
   # @param [Integer] id the ID of the project variable - this is required
   # @param [String] variable_name the name of the variable - exists in variable_names_cv
   # @param [String] variable_code the unique code for identifying this variable
   # @param [String] speciation the speciation of the vairable - may be "unknown"
   #  
   # @author Sean Cleveland
   #
   # @api public
   def update_project_variable
     @variable = ""
     begin
       if !params[:id].empty?
         parent.managed_repository do
           @variable = Voeis::Variable.get(params[:id].to_i)
           Voeis::Variable.properties.each do |prop|
             if prop.name.to_s != "id"
               if !params[prop.name].nil?
                 @variable[prop.name.to_s] = params[prop.name.to_s]
               end
             end
           end
           @variable.save!
         end
       end
     rescue Exception => e
       @variable=Hash.new
       @variable[:errors] = e.message
     end #end rescue
     respond_to do |format|
       format_response(@variable, format)
     end
   end
   
   def update_voeis_variable
     @variable = ""
     if !params[:id].empty?
       @variable = Voeis::Variable.get(params[:id].to_i)
       Voeis::Variable.properties.each do |prop|
         if prop.name.to_s != "id"
           if !params[prop.name].nil?
             @variable[prop.name.to_s] = params[prop.name.to_s]
           end
         end
       end
       @variable.save
     end
     respond_to do |format|
       format_response(@variable, format)
     end
   end
   
   
   def get_dojo_voeis_variables
     @variables = Hash.new
     @variables = {:identifer=>"id", :label=> "variable_code", :items => Voeis::Variable.all()}
     respond_to do |format|
       format_response(@variables, format)
     end
   end
   
   
   # get_project_site_variables
    # API for creating a new variable within in a project
    # 
    # @example http://voeis.msu.montana.edu/projects/e787bee8-e3ab-11df-b985-002500d43ea0/apivs/get_project_site_variables.json?site_ids[]=1&site_ids[]=5&site_ids[]=7
    #
    # @param [Integer] site_ids the array of IDs of the project site - this is required
    #  
    # @author Sean Cleveland
    #
    # @api public
    def get_project_site_variables
      @variables =""
      parent.managed_repository do
        sites = Voeis::Site.all(:id=>params[:site_ids])
        @variables = sites.variables
      end
      respond_to do |format|
        format_response(@variables, format)
      end
    end
   
  # import_voeis_variable_to_project
  # API for getting a variable within in the VOEIS system into the current project
  #
  #
  # @example http://voeis.msu.montana.edu/projects/e787bee8-e3ab-11df-b985-002500d43ea0/apivs/get_voeis_variables.json?
  # @example http://voeis.msu.montana.edu/projects/e787bee8-e3ab-11df-b985-002500d43ea0/apivs/get_voeis_variables.xml?
  # 
  # @param [Integer] voeis_variable_id, the id of the Voeis variable to import
  # 
  # @author Sean Cleveland
  #
  # @api public
  def import_voeis_variable_to_project    
    @var = Voeis::Variable.get(params[:voeis_variable_id].to_i)
    @new_var
    parent.managed_repository do     
        begin      
          @new_var = Voeis::Variable.first_or_create(
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
        rescue
          @new_var = {"error" => @new_var.errors.inspect().to_s}
        end
    end#managed repo
    respond_to do |format|
      format_response(@new_var, format)
    end
  end
 
 
 
  def dojo_variables_for_tree
    @var_hash = Hash.new
    @var_hash = {:identifier=> 'id', :label=> 'name', :items=>Voeis::Variable.all().map{|v| {:id=>v.id, :name=>v.variable_code, :type=>"variable_code"}}}
    Voeis::GeneralCategoryCV.each do |cat|
      cat_hash=Hash.new
      cat_hash={:id=>cat.term, :name=>cat.term, :type=>"general_category"}
      vars = Voeis::Variable.all(:general_category=>cat.term,:fields=>[:variable_name],:unique=>true, :order=>[:variable_name.asc]).map{|v| v.variable_name}
           cat_hash[:children] = vars.map{|v| {"_reference"=>v+cat.term}}
           @var_name_array = Array.new
           vars.each do |v| 
             var_name_hash = Hash.new
             var_name_hash = {:id=>v+cat.term, :name=> v,:type=>"variable_name"}
             var_name_hash[:children] =  Voeis::Variable.all(:general_category=>cat.term, :variable_name=> v ).map{|var| {"_reference"=>var.id.to_s}}
             @var_name_array << var_name_hash
           end
      @var_hash[:items] << cat_hash
      @var_hash[:items] = @var_hash[:items] + @var_name_array
    end
    respond_to do |format|
      format_response(@var_hash, format)
    end
  end
 
  # **********SAMPLES*************** 
   
  # get_project_samples
  # API for getting all the samples within the current project
  #
  #
  # @example http://voeis.msu.montana.edu/projects/e787bee8-e3ab-11df-b985-002500d43ea0/apivs/get_project_samples.json?
  # @example http://voeis.msu.montana.edu/projects/e787bee8-e3ab-11df-b985-002500d43ea0/apivs/get_project_samples.xml?
  # @author Sean Cleveland
  #
  # @api public
  def get_project_samples
   @samples = ""
   parent.managed_repository do
     @samples = Voeis::Sample.all()
   end
   respond_to do |format|
     format_response(@samples, format)
   end
  end

  # get_project_sample
  # API for getting a sample within the current project
  #
  #
  # @example http://voeis.msu.montana.edu/projects/8524239c-e700-11df-8da7-6e9ffb75bc80/apivs/get_project_samples.json?api_key=d7ef0f4fe901e5dfd136c23a4ddb33303da104ee1903929cf3c1d9bd271ed1a7
  # @example http://voeis.msu.montana.edu/projects/e787bee8-e3ab-11df-b985-002500d43ea0/apivs/get_project_samples.xml?
  # 
  # @param [Integer] id the id of the sample within the project
  #
  # @author Sean Cleveland
  #
  # @api public
  def get_project_sample
   @sample = ""
   parent.managed_repository do
     @sample = Voeis::Sample.get(params[:id].to_i)
   end
   
   respond_to do |format|
     format_response(@sample, format)
   end
  end
   
  # create_project_sample
  # API for creating a new sample within the current project
  #
  #
  # @example http://voeis.msu.montana.edu/projects/b6db01d0-e606-11df-863f-6e9ffb75bc80/apivs/create_project_sample.json?site_id=1&sample_type=Unknown&local_date_time=2010-11-12T12:25:31-07:00&material=insect&lab_sample_code=sampleco0004&lab_method_id=1&api_key=d7ef0f4fe901e5dfd136c23a4ddb33303da104ee1903929cf3c1d9bd271ed1a7
  # @example http://voeis.msu.montana.edu/projects/e787bee8-e3ab-11df-b985-002500d43ea0/apivs/get_project_samples.xml?
  # 
  # @param [Integer] id the id of the sample within the project
  # @param [String] sample_type, this is what type of sample this is example "grab"
  # @param [DateTime] local_date_time, this is the timestamp the sample was taken
  # @param [String] material, the type of the material the sample is examples (water, insect)
  # @param [String] lab_sample_code, this it the unique code used to identify the sample example "stream_sample_001"
  # @param [Integer] lab_method_id, this is the id of the method used to collect this sample
  # @param [Integer] site_id, this the id of the site that this sample was collected at
  #
  # @author Sean Cleveland
  #
  # @api public
  def create_project_sample
   @sample = ""
   parent.managed_repository do
     @site = Voeis::Site.get(params[:site_id].to_i)
     if @site.nil?
       @sample[:error] = "The Site ID:" + params[:site_id] +" is incorrect."
     else
       @sample = Voeis::Sample.new(:sample_type => params[:sample_type],
                                   :local_date_time => params[:local_date_time],
                                   :material => params[:material],
                                   :lab_sample_code => params[:lab_sample_code],
                                   :lab_method_id => params[:lab_method_id].to_i) 
       @sample.sites << @site
       begin
         @sample.save
       rescue
         @sample = {"error" => @sample.error.inspect().to_s}
       end
     end
   end
   respond_to do |format|
     format_response(@sample, format)
   end
  end
  
  # get_project_sample_measurements
  # API for getting all the samples within the current project
  #
  #
  # @example http://voeis.msu.montana.edu/projects/e787bee8-e3ab-11df-b985-002500d43ea0/apivs/get_project_samples.json?
  # @example http://voeis.msu.montana.edu/projects/e787bee8-e3ab-11df-b985-002500d43ea0/apivs/get_project_samples.xml?
  # 
  # @param [Integer] sample_id, the id of the sample to fetch measurements for
  #
  # @author Sean Cleveland
  #
  # @api public
  def get_project_sample_measurements
   @measurements = ""
   parent.managed_repository do
     @measurements = Voeis::Sample.get(params[:sample_id].to_i).data_values
   end
   respond_to do |format|
     format_response(@measurements, format)
   end
  end
  
  
  # create_project_sample_measurement
  # API for creating a new sample measurement within the current project
  #
  #
  # @example http://voeis.msu.montana.edu/projects/b6db01d0-e606-11df-863f-6e9ffb75bc80/apivs/create_project_sample_measurement.json?sample_id=5&variable_id=30&value=10.23423&replicate=3&api_key=d7ef0f4fe901e5dfd136c23a4ddb33303da104ee1903929cf3c1d9bd271ed1a7
  # @example curl -d "sample_id=5&variable_id=30&value=10.23423&replicate=3&api_key=d7ef0f4fe901e5dfd136c23a4ddb33303da104ee1903929cf3c1d9bd271ed1a7" http://voeis.msu.montana.edu/projects/b6db01d0-e606-11df-863f-6e9ffb75bc80/apivs/create_project_sample_measurement.json?
  # 
  # @param [Integer] sample_id the id of the sample within the project
  # @param [Integer] variable_id the id of variable to associate with this measurement
  # @param [String] value, this is what type of sample this is example "grab"
  # @param [String] replicate, specify if what replicate this was (OPTIONAL)
  #
  # @author Sean Cleveland
  #
  # @api public
  def create_project_sample_measurement
    @measurement = ""

     parent.managed_repository do
       @sample = Voeis::Sample.get(params[:sample_id].to_i)
       @variable = Voeis::Variable.get(params[:variable_id].to_i)
       if @sample.nil? 
         @measurement = {:error => "The Site ID:" + params[:site_id] +" is incorrect."}
       else
         if @variable.nil?
           @measurement = {:error => "The Variable ID:" + params[:variable_id] +" is incorrect."}
         else
           @measurement = Voeis::DataValue.new(                      
                          :data_value => /^[-]?[\d]+(\.?\d*)(e?|E?)(\-?|\+?)\d*$|^[-]?(\.\d+)(e?|E?)(\-?|\+?)\d*$/.match(params[:value].to_s) ? params[:value].to_f : -9999.0,
                          :local_date_time => @sample.local_date_time,
                          :utc_offset => @sample.local_date_time.to_time.utc_offset/(60*60),  
                          :date_time_utc => @sample.local_date_time.to_time.utc.to_datetime,            
                          :replicate => params[:replicate].empty? ? "None" : params[:replicate].to_s,
                          :string_value => params[:value].to_s)                                   
           @measurement.site << @sample.sites.first
           @measurement.sample << @sample
           @measurement.variable << @variable
           begin
             @measurement.save
           rescue
             @measurement = {"error" => @measurement.errors.inspect().to_s}
           end
           
           begin
             @sample.variables << @variable
             @sample.save
           rescue
             @measurement = @measurement.merge({"error" => @sample.errors.inspect().to_s})
           end
          end
       end
     end
     respond_to do |format|
       format_response(@measurement, format)
     end
  end
   
  #########DataSets######################################
  
  # create_project_data_set
   # API for creating a new data set object
   #
   #
   # @example http://voeis.msu.montana.edu/projects/b6db01d0-e606-11df-863f-6e9ffb75bc80/apivs/get_project_data_sets&api_key=d7ef0f4fe901e5dfd136c23a4ddb33303da104ee1903929cf3c1d9bd271ed1a7
   # 
   # @param [String] :name  -the unique name of this dataset for the project
   # @param [String] :type - specify a data set type to retreive all of. If not specifed the type will be "default"
   # # @param [Text] :description - the description of the data set. Optional
   #
   # @return [JSON String] The created data set object
   #
   # @author Sean Cleveland
   #
   # @api public
   def create_project_data_set
     @data_set =""
     parent.managed_repository do
       if params[:name]
         if Voeis::DataSet.first(:name => params[:name]).nil?
           if params[:type].empty?
             params[:type] = "default"
           end
           if params[:description].nil?
             params[:description] = ""
           end
           debugger
           @data_set = Voeis::DataSet.create(:name=>params[:name], :type=>params[:type], :description=>params[:description])
         else
           @data_set = {"error" => "The name: #{params[:name]} already exists as data set."}
         end
       else
         @data_set = {"error" => "The name parameter is required to create a new data set."}
       end
     end
     respond_to do |format|
        format_response(@data_set, format)
     end
   end
  
  # get_project_data_sets
  # API for fetching all data sets objects from a project.  NOTE this does not return the data values for a data set
  #
  #
  # @example http://voeis.msu.montana.edu/projects/b6db01d0-e606-11df-863f-6e9ffb75bc80/apivs/get_project_data_sets&api_key=d7ef0f4fe901e5dfd136c23a4ddb33303da104ee1903929cf3c1d9bd271ed1a7
  # 
  # @param [String] :type specify a data set type to retreive all of. OPTIONAL
  #
  # @return [JSON String] an array of data_sets that exist for the project and each ones properties
  #
  # @author Sean Cleveland
  #
  # @api public
  def get_project_data_sets
    @data_sets =""
    parent.managed_repository do
      if params[:type]
        @data_sets = Voeis::DataSet.all(:type=>params[:type])
      else
        @data_sets = Voeis::DataSet.all
      end
    end
    respond_to do |format|
       format_response(@data_sets, format)
    end
  end
  
  # get_project_data_set_data
  # API for fetching all of a data sets data from a project
  #
  #
  # @example http://voeis.msu.montana.edu/projects/b6db01d0-e606-11df-863f-6e9ffb75bc80/apivs/get_project_data_set_data.json&api_key=d7ef0f4fe901e5dfd136c23a4ddb33303da104ee1903929cf3c1d9bd271ed1a7&data_set_id=1
  # 
  # @param [Integer] :data_set_id
  # @param [Boolean] :small_data if true this will return only local_date_time and the data_values. OPTIONAL
  # @param [Integer] :variable_id if true this will return only data values that are associated with this variable. OPTIONAL
  # 
  # @return [JSON String] an array of data_sets that exist for the project and each ones properties
  #
  # @author Sean Cleveland
  #
  # @api public
  def get_project_data_set_data
    @data_set_data =""
    @data_hash = Hash.new()
    sql =""
    parent.managed_repository do
      @data_set_data = Voeis::DataSet.get(params[:data_set_id].to_i).data_values    
      if params[:small_data] == 'true'
        if params[:variable_id]
          sql = "SELECT local_date_time, data_value FROM  voeis_data_values WHERE variable_id=#{params[:variable_id]} AND id IN ( #{@data_set_data.map{|k| k.id}.join(',')})"
        else
          sql = "SELECT local_date_time, data_value FROM  voeis_data_values WHERE id IN ( #{@data_set_data.map{|k| k.id}.join(',')})"
        end  
        @data_hash[:data] = repository.adapter.select(sql)
      else
         @data_hash[:data] = @data_set_data
      end
      @data_hash[:data_set] = Voeis::DataSet.get(params[:data_set_id].to_i)
    end
    respond_to do |format|
       format_response(@data_hash, format)
    end
  end
  
  
   # add_data_to__project_data_set
   # API for adding data values to an existing data set within a project
   #
   #
   # @example http://voeis.msu.montana.edu/projects/b6db01d0-e606-11df-863f-6e9ffb75bc80/apivs/add_data_to__project_data_set.json&api_key=d7ef0f4fe901e5dfd136c23a4ddb33303da104ee1903929cf3c1d9bd271ed1a7&data_set_id=1&data_value_ids[]=21&data_value_ids[]=13
   # 
   # @param [Integer] :data_set_id
   # @param [Array] :data_value_ids - this is an array of the data value ids to add to the data set.
   # @param [Boolean] :small_data if true this will return only local_date_time and the data_values. OPTIONAL
   # 
   # @return [JSON Object] an array of data_values that exist for the data_set
   #
   # @author Sean Cleveland
   #
   # @api public
   def add_data_to_project_data_set
     @data_set_data =""
     @data_hash = Hash.new()
     sql =""
     parent.managed_repository do
       if data_set = Voeis::DataSet.get(params[:data_set_id].to_i)
         debugger
         data_set.add_data_values(params[:data_value_ids])
         @data_set_data = data_set.data_values    
         if params[:small_data] == 'true'
           sql = "SELECT local_date_time, data_value FROM  voeis_data_values WHERE id IN ( #{@data_set_data.map{|k| k.id}.join(',')})"
           @data_hash[:data] = repository.adapter.select(sql)
         else
            @data_hash[:data] = @data_set_data
         end
         @data_hash[:data_set] = Voeis::DataSet.get(params[:data_set_id].to_i)
       else
         @data_hash = {"error" => "The id: #{params[:data_set_id]} does not exist as data set."}
       end
     end
     respond_to do |format|
        format_response(@data_hash, format)
     end
   end
   
   # remove_data_from_project_data_set
    # API for removing data values from an existing data set within a project
    #
    #
    # @example http://voeis.msu.montana.edu/projects/b6db01d0-e606-11df-863f-6e9ffb75bc80/apivs/remove_data_to__project_data_set.json&api_key=d7ef0f4fe901e5dfd136c23a4ddb33303da104ee1903929cf3c1d9bd271ed1a7&data_set_id=1&data_value_ids[]=21&data_value_ids[]=13
    # 
    # @param [Integer] :data_set_id
    # @param [Array] :data_value_ids - this is an array of the data value ids to remove from the data set.
    # @param [Boolean] :small_data if true this will return only local_date_time and the data_values. OPTIONAL
    # 
    # @return [JSON Object] an array of data_values that exist for the data_set
    #
    # @author Sean Cleveland
    #
    # @api public
    def remove_data_from_project_data_set
      @data_set_data =""
      @data_hash = Hash.new()
      sql =""
      parent.managed_repository do
        if data_set = Voeis::DataSet.get(params[:data_set_id].to_i)
          data_set.remove_data_values(params[:data_value_ids])
          @data_set_data = data_set.data_values    
          if params[:small_data] == 'true'
            sql = "SELECT local_date_time, data_value FROM  voeis_data_values WHERE id IN ( #{@data_set_data.map{|k| k.id}.join(',')})"
            @data_hash[:data] = repository.adapter.select(sql)
          else
             @data_hash[:data] = @data_set_data
          end
          @data_hash[:data_set] = Voeis::DataSet.get(params[:data_set_id].to_i)
        else
          @data_hash = {"error" => "The id: #{params[:data_set_id]} does not exist as data set."}
        end
      end
      respond_to do |format|
         format_response(@data_hash, format)
      end
    end
    
    ###### Simulations stuff####
    # 
    # curl -F datafile=@summaryAF.csv -F site_id=1 -F sim_col=1 http://localhost:3000/projects/168b2812-51a4-11e1-ad78-c82a14fffebf/apivs/upload_simulation.json?api_key=e79b135dcfeb6699bbaa6c9ba9c1d0fc474d7adb755fa215446c398cae057adf
    def upload_simulation
      parent.managed_repository do
        first_row = Array.new
        flash_error = Hash.new
        @msg = "There was a problem parsing this file."
        name = Time.now.to_s + params[:datafile].original_filename 
        directory = "temp_data"
        @new_file = File.join(directory,name)
        File.open(@new_file, "wb"){ |f| f.write(params['datafile'].read)}
        site = Voeis::Site.get(params[:site_id].to_i)
        unless data_stream = Voeis::DataStream.first(:name => params[:datafile].original_filename) 
          #create a datatemplate
          data_stream = Voeis::DataStream.create(:name => params[:datafile].original_filename, :filename => params[:datafile].original_filename, :type=>"Simulation")
          data_stream.sites << site
          data_stream.save
          #csv = CSV.open(@new_file, "r")
          csv = CSV.read(@new_file)
          row = csv[0]
          debugger
          units_id =341#unknown
          counter = 0
          row.each do |v|
            var =""
            repository("default") do
              var = Voeis::Variable.first_or_create(:variable_name=>v, :variable_code => "#{v}_code",:variable_units_id =>  units_id)
            end
            if counter+1 == params[:sim_col].to_i
              data_stream_column = Voeis::DataStreamColumn.create(
                                         :column_number => counter,
                                         :name => "SampleID",
                                         :type =>"SampleID",
                                         :unit => "NA",
                                         :original_var => "NA")
            else
              data_stream_column = Voeis::DataStreamColumn.create(
                                    :column_number => counter,
                                    :name =>         var.variable_code,
                                    :original_var => var.variable_name,
                                    :unit =>         "NA",
                                    :type =>         "NA")           

              if Voeis::Variable.get(var.id).nil?
                 variable = Voeis::Variable.new
                 variable.attributes = var.attributes
                 variable.save!
               else
                variable = Voeis::Variable.get(var.id)
               end
               site.variables << variable
               site.save
               data_stream_column.variables << variable
            end
            data_stream_column.data_streams << data_stream
            data_stream_column.save
            counter +=1
          end
        end
        flash_error = flash_error.merge(Voeis::DataValue.parse_sim_csv(@new_file, data_stream.id, params[:site_id], 2,nil,nil,user.id))        
       respond_to do |format|
          if params.has_key?(:api_key)
            format.json
          end
          if flash_error[:error].nil?
            if flash_error[:success].nil?
              flash_error[:success] = "File was parsed succesfully."
            end
            data_stream.sites.first.update_site_data_catalog
            #flash_error = flash_error.merge({:last_record => data_stream_template.data_stream_columns.sensor_types.sensor_values.last(:order =>[:id.asc]).as_json}) 
          end
          format.json do
            render :json => flash_error.to_json, :callback => params[:jsoncallback]
          end
          format.xml do
            render :xml => flash_error.to_xml
          end
        end
      end
     
    end
  private
 
     
     #'http://glassfish.msu.montana.edu/yogo/projects/Big%20Sky.json?api_key=Red-0bl_n0qxeOIwh4WQ&sitecode=UPGL-GLTNR24--MSU_UPGL-GLTNR24_MF_ESTBSWS&sensors[]=H2OCond_Avg&sensors[]=H2OTemp_Avg&sensors[]=AirTemp_Avg&sensors[]=AirTemp_SMP&hours=48&jsoncallback=?'
     def get_project_data_by_site_and_sensor
      
     end
end