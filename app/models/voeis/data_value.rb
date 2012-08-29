class Voeis::DataValue
  include DataMapper::Resource
  include Facet::DataMapper::Resource
  include Yogo::Versioned::DataMapper::Resource

  property :id,                         Serial
  property :data_value,                 Float,    :required => true,  :default => 0
  property :value_accuracy,             Float
  property :local_date_time,            DateTime, :required => true,  :default => DateTime.now, :index => true
  property :utc_offset,                 Float,    :required => true,  :default => 1.0
  property :date_time_utc,              DateTime, :required => true,  :default => DateTime.now
  property :observes_daylight_savings,  Boolean,  :required => true, :default => false
  property :replicate,                  String,   :required => true,  :default => "original"
  property :vertical_offset,            Float,    :required=>false
  property :end_vertical_offset,        Float,    :required=>false
  property :string_value,               String,   :required => true, :default => "Unknown"
  property :quality_control_level,      Integer,  :required=>true, :default=>0
  property :datatype,                  String,    :default =>"Sample", :index =>true
  property :published,                  Boolean,  :required => false
  property :site_id,                    Integer,  :index => true
  property :variable_id,                Integer, :index => true
  property :filename,                   String, :required => true, :length => 512, :default=>"unknown"
  property :his_id,                     Integer, :required => false
  property :sample_id,                  Integer, :index => true, :default => -1
  yogo_versioned
  #timestamps :at
  
  has 1, :site,       :model => "Voeis::Site",     :through => Resource
  has 1,:source,       :model => "Voeis::Source",       :through => Resource
   
  has 1, :sample,     :model => "Voeis::Sample",   :through => Resource
  has n, :meta_tags,  :model => "Voeis::MetaTag",  :through => Resource
  has 1, :variable,   :model => "Voeis::Variable", :through => Resource
  has n, :data_streams,  :model => "Voeis::DataStream", :through => Resource
  has 1, :sensor_type,  :model => "Voeis::SensorType", :through => Resource
  has n, :data_sets,  :model =>"Voeis::DataSet", :through => Resource
  #has n, :method,     :model => "Voeis::Method", :through => Resource
  
  
  def local_date_time
    # d = [:year, :mon, :day, :hour, :min, :sec].map{|q| @local_date_time.send(q)}
    # d << (utc_offset/24).to_f
    # #puts d
    # DateTime.new(*d) 
    tz0 = utc_offset.to_s.split('.')
    tz = (tz0[0][0]=='-' ? '-' : '+')+('00'+tz0[0].to_i.abs.to_s)[-2,2]+':'
    tz += tz0.count>1 ? ('0'+((('.'+tz0[1]).to_f*100).to_i*0.6).to_i.to_s)[-2,2] : '00'
    @local_date_time.to_datetime.change(:offset => tz)  ### "#{utc_offset}:00")
  end
  
  def date_time_utc
    # d = [:year, :mon, :day, :hour, :min, :sec].map{|q| @date_time_utc.send(q)}
    # d << (0.0/24).to_f
    # #puts d
    # DateTime.new(*d) 
    @date_time_utc.to_datetime.change(:offset => "+00:00")
  end
  
  def store_to_his(his_site_id, his_var_id, his_src_id)
    if self.his_id.nil?
      begin
        his_val = His::DataValue.first_or_create(:data_value => self.data_value,
                                                :value_accuracy => self.value_accuracy,
                                                :local_date_time => self.timestamp,
                                                :utc_offset => self.utc_offset,
                                                :date_time_utc => self.timestamp,
                                                :site_id => his_site_id,
                                                :variable_id => his_var_id,
                                                :offset_value => self.vertical_offset,
                                                :offset_type_id => 1,
                                                :censor_code => 'nc',
                                                :qualifier_id => 1,
                                                :method_id => 0,
                                                :source_id => his_src_id,
                                                #:sample_id => 3,
                                                #:derived_from_id => 1,
                                                :quality_control_level_id => self.quality_control_level)
         his_val.valid?                      
         puts his_val.errors.inspect
         his_val.save
         self.his_id = his_val.id
         self.published =true
         self.save
         his_val
       rescue
          "DataValue ID:#{self.id} did not store to HIS."
       end
     else
       His::DataValue.get(self.his_id)
     end
  end
  
  
  # Parses a csv file using an existing data_column template
  # column values are stored in data_values
  #
  # @example parse_logger_csv_header("filename")
  #
  # @param [String] csv_file
  # @param [Object] data_stream_template
  # @param [Object] site
  #
  # @return
  #
  # @author Yogo Team
  #
  # @api publicsenosr
  def self.parse_logger_csv(csv_file, data_stream_template_id, site_id, start_line, sample_type, sample_medium, user_id)
    #puts "USER ID: #{user_id} ********************************"
    #Determine how the time is stored
    errors = ""
    if !Voeis::DataStream.get(data_stream_template_id).data_stream_columns.first(:name => "Timestamp").nil?
      data_timestamp_col = Voeis::DataStream.get(data_stream_template_id).data_stream_columns.first(:name => "Timestamp").column_number
      date_col=""
      time_col=""
    else
      data_timestamp_col = ""
      date_col = Voeis::DataStream.get(data_stream_template_id).data_stream_columns.first(:name => "Date").column_number
      time_col = Voeis::DataStream.get(data_stream_template_id).data_stream_columns.first(:name => "Time").column_number
    end
    if !Voeis::DataStream.get(data_stream_template_id).data_stream_columns.first(:name => "VerticalOffset").nil?
      vertical_offset_col = Voeis::DataStream.get(data_stream_template_id).data_stream_columns.first(:name => "VerticalOffset").column_number
    else
      vertical_offset_col = ""
    end
     if !Voeis::DataStream.get(data_stream_template_id).data_stream_columns.first(:name => "EndingVerticalOffset").nil?
        end_vertical_offset_col = Voeis::DataStream.get(data_stream_template_id).data_stream_columns.first(:name => "EndingVerticalOffset").column_number
      else
        end_vertical_offset_col = ""
      end
    if start_line.nil?
      start_line = Voeis::DataStream.get(data_stream_template_id).start_line
    end
    #site = Voeis::Site.get(site_id)
    data_col_array = Array.new
    sensor_col_array = Array.new
    sensor_col_hash = Hash.new
    sensor_cols = Array.new
    variable_cols = Array.new
    meta_tag_cols = Array.new
    meta_tag_hash = Hash.new
    sample_id = -1
    #puts "Creating Hashes ********************************"
    Voeis::DataStream.get(data_stream_template_id).data_stream_columns.each do |col|
      data_col_array[col.column_number] = [col.variables.first, col.unit, col.name]
      if col.name != "Ignore"  && col.name != "Timestamp"  && col.name != "Time" && col.name != "Date" && col.name !=  "VerticalOffset" && col.name !=  "EndingVerticalOffset" && col.name !=  "SampleID" && col.name != "ignore" && col.name != "MetaTag"
        #puts "Variable COL ********************************"
        variable_cols << col.column_number
        
        unless col.sensor_types.empty?
          #puts "Sensor HASH ********************************"
          sensor_cols << col.column_number
          sensor_col_hash[col.column_number.to_s] = col.sensor_types.first.id
        end
      elsif col.name ==  "SampleID"
        #puts "SAMPLE ID COL ********************************"
        sample_id = col.column_number
      elsif col.name = "MetaTag"
        #puts "MetaTag HASH ********************************"
        meta_tag_cols = col.column_number
        meta_tag_hash[col.column_number.to_s] = col.meta_tag
      end
      # sensor_col_array[col.column_number] = [col.sensor_types.first, col.unit, col.name]
      # if col.name != "ignore"  && col.name != "Timestamp"  && col.name != "Time" && col.name != "Date" && col.name !=  "VerticalOffset" && col.name != "Ignore"
        
      #end
    end
    #puts "DONE Creating Hashes ********************************"
    if Voeis::DataValue.last(:order =>[:id.asc]).nil?
      starting_id = -9999
    else
      starting_id = Voeis::DataValue.last(:order =>[:id.asc]).id
    end
    rows_parsed = 0
    header_row=""  
    source_id = Voeis::DataStream.get(data_stream_template_id).source.id
    dst_time = 0
    dst = false
    if Voeis::DataStream.get(data_stream_template_id).DST
       dst_time = 1
       dst = true
    end
    user = nil
    repository("default") do
      user = User.get(user_id)
    end
    create_comment = "Created at #{created_at} by #{user.first_name} #{user.last_name} [#{user.login}]"
    #rows = CSV.read(csv_file)
    results = Hash.new
    total_results = Array.new
    total_records = 0
    skipped_rows = 0
    CSV.foreach(csv_file) do |row|
    #rows.each do |row|
      if !row.nil?
        results = Array.new
        if rows_parsed >= start_line-1# || start_line == 1
        #   (1..start_line-1).each do
        #     header_row = csv.readline
        #   end
        # end
        #while row = csv.readline #&& !row.empty?
          if !row[data_timestamp_col].nil? && !row[data_timestamp_col].empty?        
          Rails.logger.info '#{row.join(', ')}'
          #puts row.join(', ')
            results = parse_logger_row(data_timestamp_col, data_stream_template_id, vertical_offset_col, date_col, time_col,  row, site_id, data_col_array, variable_cols, meta_tag_cols, meta_tag_hash, sample_id, sample_type, sample_medium, end_vertical_offset_col,sensor_col_array,sensor_cols, sensor_col_hash, source_id, dst_time, dst, user, csv_file, rows_parsed)
            
            if results[:result_ids].empty?
              skipped_rows += 1
              unless results[:errors].empty?
                errors = errors + " | " + results[:errors]
              end
            else
              total_records = total_records + results[:result_ids].length
              total_results << results[:result_ids]
            end
          else 
            #puts "EMPTY ROW"
            skipped_rows +=1 
          end
        end
        rows_parsed += 1 
      end
    end
    #end
    if total_records != 0
      data_value = Voeis::DataValue.get(total_results.last)#:order =>[:id.asc]) 
    else
       data_value = {:message => "No new Records were saved - it appears this file has already been parsed and stored."}
    end
    return_hash = {:total_records_saved => total_records, :rows_skipped => skipped_rows, :total_rows_parsed => rows_parsed, :last_record => Voeis::DataValue.last(:site_id=> site_id, :variable_id => data_col_array[variable_cols.last][0].id, :order => [:created_at]).as_json, :last_record_for_this_file => data_value.as_json,:errors=>errors}
  end
  
  
  
  # Parses a csv row using an existing data_column template
  # column values are stored in sensor_values
  #
  # TODO wrap associations in A POSTGRES Transaction
  #
  # @example parse_logger_csv_header("filename")
  #
  # @param [String] csv_file
  # @param [Object] data_stream_template
  # @param [Object] site
  #
  # @return
  #
  # @author Yogo Team
  #
  # @api public
  def self.parse_logger_row(data_timestamp_col, data_stream_id, vertical_offset_col, date_col, time_col, row, site_id, data_col_array, variable_cols, meta_tag_cols, meta_tag_hash, sample_id, sample_type, sample_medium, end_vertical_offset_col, sensor_col_array,sensor_cols, sensor_col_hash, source_id, dst_time, dst, user,filename, row_number)
    require 'chronic'  #for robust timestamp parsing
     #puts "INSIDE USER ID: #{user.id} ********************************"
    name = 2
    variable = 0
    sensor = 0
    unit = 1
    errors = ""
    result_ids = Array.new
    meta_ids = Array.new
    begin
    #Voeis::SensorValue.transaction do
    #timestamp = (data_timestamp_col == "") ? Time.parse(row[date_col].to_s + ' ' + row[time_col].to_s).strftime("%Y-%m-%dT%H:%M:%S%z") : row[data_timestamp_col.to_i]
    vertical_offset = vertical_offset_col == "" ? 0.0 : row[vertical_offset_col.to_i].to_f
    end_vertical_offset = end_vertical_offset_col == "" ? 0.0 : row[end_vertical_offset_col.to_i].to_f
    data_stream = Voeis::DataStream.get(data_stream_id)
    if DateTime.parse(row[data_timestamp_col])
      sample_datetime = DateTime.parse(row[data_timestamp_col])
    else
      sample_datetime = Chronic.parse(row[data_timestamp_col]).to_datetime
    end
    # timestamp = DateTime.civil(sample_datetime.year,sample_datetime.month,
    #                sample_datetime.day,sample_datetime.hour,sample_datetime.min,
    #                sample_datetime.sec, (data_stream.utc_offset+dst_time)/24.to_r)
    timestamp = sample_datetime.change(:offset => "#{(data_stream.utc_offset+dst_time)}:00")
    
    #if t = Date.parse(timestamp) rescue nil?
    #if (Voeis::DataValue.first(:local_date_time => timestamp) & 
    
    if Voeis::DataValue.first(:datatype=>data_stream.type, :local_date_time=>timestamp, :site_id=> site_id, :variable_id => data_col_array[variable_cols[0]][variable].id).nil? || sample_id != -1
          #puts "INSIDE For Insert ********************************"
          created_at = updated_at = Time.now.strftime("%Y-%m-%dT%H:%M:%S%z")
          create_comment = "Created at #{created_at} by #{user.first_name} #{user.last_name} [#{user.login}]"
          row_values = []
          meta_values =[] 
          newsample_id = -1
          if sample_id != -1
            sample_value=[]
            #Lets create a sample or fetch the one already there.
            #sql = DataMapper.generate_sql_execute(
            
            newsample_id= Voeis::Sample.first_or_create(:sample_type=>sample_type, :material=>sample_medium, :lab_sample_code=>row[sample_id], :local_date_time=>timestamp,:created_at=>created_at, :updated_at=>updated_at, :updated_by=>user.id, :updated_comment=>create_comment).id
            #sql = "INSERT INTO \"voeis_samples\" (\"sample_type\",\"material\",\"lab_sample_code\",\"local_date_time\",\"created_at\",\"updated_at\",\"updated_by\",\"updated_comment\") VALUES "
            #sql << "('#{sample_type}', '#{sample_medium}','#{DataMapper.sanitize(row[sample_id])}', '#{timestamp}','#{created_at}', '#{updated_at}', #{user.id},'#{create_comment}')"
            #sql << sample_value.join(',')
            #sql << " RETURNING \"id\""
            
            #sample_result = repository.adapter.execute(sql)
            #newsample_id =sample_result.insert_id
          end
          sql_array = []
          (0..row.size-1).each do |i|
            if i != data_timestamp_col && i != date_col && i != time_col && i != vertical_offset_col && data_col_array[i][name] != "Ignore" && data_col_array[i][name] != "EndingVerticalOffset" && data_col_array[i][name] != "SampleID" && data_col_array[i][name] != "Ignore" && data_col_array[i][name] != "MetaTag"
                cv = /^[-]?[\d]+(\.?\d*)(e?|E?)(\-?|\+?)\d*$|^[-]?(\.\d+)(e?|E?)(\-?|\+?)\d*$/.match(row[i]) ? row[i].to_f : -9999.0
                row_values << "(#{cv.to_s}, '#{timestamp.to_s}', #{vertical_offset},FALSE, '#{row[i].to_s.escape_quotes_for_sql}', '#{created_at}', '#{updated_at}', #{user.id},'#{create_comment}', #{data_stream.utc_offset+dst_time},'#{timestamp.utc.to_s}','#{dst}',#{end_vertical_offset},#{data_col_array[i][variable].quality_control.to_f},'#{data_stream.type}', #{site_id},  #{data_col_array[i][variable].id},  '#{filename}', #{newsample_id} )"
                #sql_array << DataMapper.generate_sql_execute(Voeis::DataValue.create(:data_value=>cv, :local_date_time=>timestamp, :vertical_offset=>vertical_offset, :published=>false, :string_value=>row[i].to_s, :created_at=>created_at, :updated_at=>updated_at,
                #                             :updated_by=>user.id, :updated_comment=>create_comment, :utc_offset=>data_stream.utc_offset+dst_time, :date_time_utc=>timestamp.utc, :observes_daylight_savings=>dst, 
               #                              :end_vertical_offset=>end_vertical_offset, :quality_control_level=> data_col_array[i][variable].quality_control.to_f, :datatype=>data_stream.type, :site_id=>site_id, 
               #                               :variable_id=>data_col_array[i][variable].id, :filename=>filename, :sample_id=>newsample_id))
            elsif data_col_array[i][name] == "MetaTag"
              meta_values << "('#{row[i].to_s}', '#{meta_tag_hash[i.to_s].name}', '#{meta_tag_hash[i.to_s].category}', '#{updated_at}', '#{created_at}', #{user.id}, '#{create_comment}')"
              #puts "INSIDE META VALUES ********************************"
            end #end if
          end #end loop
          if !row_values.empty?
            #puts "INSERTING DATA VALUES ********************************"
            sql = "INSERT INTO \"#{self.storage_name}\" (\"data_value\",\"local_date_time\",\"vertical_offset\",\"published\",\"string_value\",\"created_at\",\"updated_at\",\"updated_by\",\"updated_comment\", \"utc_offset\",\"date_time_utc\", \"observes_daylight_savings\", \"end_vertical_offset\", \"quality_control_level\", \"datatype\", \"site_id\", \"variable_id\", \"filename\", \"sample_id\") VALUES "
            sql << row_values.join(',')
            sql << " RETURNING \"id\""
            result_ids = repository.adapter.select(sql)
            #puts "DONE INSERTING DATA VALUES ********************************"
            #insert meta-tags
            unless meta_values.empty?
              sql = "INSERT INTO voeis_meta_tags (value, name, category, updated_at, created_at, updated_by, updated_comment) VALUES "
              sql << meta_values.join(',')
              sql << "RETURNING id"
              meta_ids = repository.adapter.select(sql)
            end
            variable_sql = Array.new
            site_sql = Array.new
            meta_tag_sql = Array.new
            sensor_sql = Array.new
            data_stream_sql = Array.new
            source_sql = Array.new
            #puts "PREPPRING ASSOCIATIONS ********************************"
            (0..result_ids.length-1).each do |i|
              variable_sql << "(#{result_ids[i]},#{data_col_array[variable_cols[i]][variable].id})"
              site_sql << "(#{result_ids[i]},#{site_id})"
              data_stream_sql <<  "(#{result_ids[i]},#{data_stream_id})"
              source_sql << "(#{result_ids[i]},#{source_id})"
              if sample_id == -1
                sensor_sql << "(#{result_ids[i]},#{sensor_col_hash[i.to_s]})"
              end
              unless meta_values.empty?
                meta_tag_sql << (0..meta_ids.length-1).map{|m| "(#{result_ids[i]},#{meta_ids[m]})"}.join(',')
              end
            end
            #puts "DONE PREPPRING ASSOCIATIONS ********************************"
            sql = "INSERT INTO \"voeis_data_value_variables\" (\"data_value_id\",\"variable_id\") VALUES "
            sql << variable_sql.join(',')
            repository.adapter.execute(sql)
            #puts "AFTER VARIABLE ASSOC ********************************"
            sql = "INSERT INTO \"voeis_data_value_sites\" (\"data_value_id\",\"site_id\") VALUES "
            sql << site_sql.join(',')
            repository.adapter.execute(sql)
            #puts "AFTER SITE ASSOC ********************************"
            sql = "INSERT INTO \"voeis_data_stream_data_values\" (\"data_value_id\",\"data_stream_id\") VALUES "
            sql << data_stream_sql.join(',')
            repository.adapter.execute(sql)
            #puts "AFTER DATA-STREAM ASSOC ********************************"
            sql = "INSERT INTO \"voeis_data_value_sources\" (\"data_value_id\",\"source_id\") VALUES "
            sql << source_sql.join(',')
            repository.adapter.execute(sql)
            #puts "AFTER SOURCE ASSOC ********************************"
            unless meta_values.empty?
              #puts "INERTING META VALUES ********************************"
              sql = "INSERT INTO \"voeis_data_value_meta_tags\" (\"data_value_id\",\"meta_tag_id\") VALUES "
              sql << meta_tag_sql.join(',')
              repository.adapter.execute(sql)
              #puts "AFTER META-TAG ASSOC ********************************"
            end
            if sample_id != -1
              sql = "INSERT INTO \"voeis_data_value_samples\" (\"data_value_id\",\"sample_id\") VALUES "
              sql << (0..result_ids.length-1).collect{|i|
                "(#{result_ids[i]},#{newsample_id})"
              }.join(',')
              repository.adapter.execute(sql)
              sql = "INSERT INTO \"voeis_sample_sites\" (\"sample_id\",\"site_id\") VALUES "
              sql << "(#{newsample_id},#{site_id})"
              repository.adapter.execute(sql)
              sql = "INSERT INTO \"voeis_sample_variables\" (\"sample_id\",\"variable_id\") VALUES "
              sql << (0..result_ids.length-1).collect{|i|
                "(#{newsample_id},#{data_col_array[variable_cols[i]][variable].id})"
              }.join(',')
              repository.adapter.execute(sql)
              #puts "AFTER SAMPLE ASSOC ********************************"
            #else
               #sql = "INSERT INTO \"voeis_data_value_sensor_types\" (\"data_value_id\",\"sensor_type_id\") VALUES "
               #sql << sensor_sql.join(',')
               #repository.adapter.execute(sql)
               #puts "AFTER SENSOR TYPE ASSOC ********************************"
           end
        end#end if

    end
    rescue Exception => e
      errors = "Row #{row_number}: #{row} - - did not store correclty.  ERROR:  #{e.inspect}"
      puts errors
    end
    return {:result_ids => result_ids, :errors => errors}
  end
  
  def self.parse_sim_csv(csv_file, data_stream_template_id, site_id, start_line, sample_type, sample_medium, user_id)
     puts "USER ID: #{user_id} ********************************"
     #Determine how the time is stored
     errors = ""
     if start_line.nil?
       start_line = Voeis::DataStream.get(data_stream_template_id).start_line
     end
     #site = Voeis::Site.get(site_id)
     data_col_array = Array.new
     sensor_col_array = Array.new
     sensor_cols = Array.new
     variable_cols = Array.new
     sample_id = -1
     Voeis::DataStream.get(data_stream_template_id).data_stream_columns.each do |col|
       data_col_array[col.column_number] = [col.variables.first, col.unit, col.name]
       if col.name != "Ignore"  && col.name != "Timestamp"  && col.name != "Time" && col.name != "Date" && col.name !=  "VerticalOffset" && col.name !=  "EndingVerticalOffset" && col.name !=  "SampleID" && col.name != "ignore"
         variable_cols << col.column_number
       elsif col.name ==  "SampleID"
         sample_id = col.column_number
       end
       sensor_col_array[col.column_number] = [col.sensor_types.first, col.unit, col.name]
       if col.name != "ignore"  && col.name != "Timestamp"  && col.name != "Time" && col.name != "Date" && col.name !=  "VerticalOffset" && col.name != "Ignore"
         sensor_cols << col.column_number
       end
     end

     if Voeis::DataValue.last(:order =>[:id.asc]).nil?
       starting_id = -9999
     else
       starting_id = Voeis::DataValue.last(:order =>[:id.asc]).id
     end
     rows_parsed = 0
     header_row=""  
     #source_id = Voeis::DataStream.get(data_stream_template_id).source.id
     dst_time = 0
     dst = false
     # if Voeis::DataStream.get(data_stream_template_id).DST
     #    dst_time = 1
     #    dst = true
     # end
     user = nil
     repository("default") do
       user = User.get(user_id)
     end
     create_comment = "Created at #{created_at} by #{user.first_name} #{user.last_name} [#{user.login}]"
     rows = CSV.read(csv_file)
     results = Hash.new
     total_results = Array.new
     total_records = 0
     skipped_rows = 0
     timestamp = DateTime.now
     CSV.foreach(csv_file) do |row|
     #rows.each do |row|
       if !row.nil?
         results = Array.new
         if rows_parsed >= start_line-1# || start_line == 1
         #   (1..start_line-1).each do
         #     header_row = csv.readline
         #   end
         # end
         #while row = csv.readline #&& !row.empty?
           #if !row[data_timestamp_col].nil? && !row[data_timestamp_col].empty?        
           Rails.logger.info '#{row.join(', ')}'
           #puts row.join(', ')
           timestamp = timestamp + 1.second
             results = parse_sim_row(data_stream_template_id,row, site_id, data_col_array, variable_cols, sample_id, "simulation", "simulation", sensor_col_array,sensor_cols, user, csv_file,timestamp)

             if results[:result_ids].empty?
               skipped_rows += 1
               unless results[:errors].empty?
                 errors = errors + " | " + results[:errors]
               end
             else
               total_records = total_records + results[:result_ids].length
               total_results << results[:result_ids]
             end
           #else 
             #puts "EMPTY ROW"
           #  skipped_rows +=1 
           #end
         end
         rows_parsed += 1 
       end
     end
     #end
     if total_records != 0
       data_value = Voeis::DataValue.get(total_results.last)#:order =>[:id.asc]) 
     else
        data_value = {:message => "No new Records were saved - it appears this file has already been parsed and stored."}
     end
     return_hash = {:total_records_saved => total_records, :rows_skipped => skipped_rows, :total_rows_parsed => rows_parsed, :last_record => Voeis::DataValue.last(:site_id=> site_id, :variable_id => data_col_array[variable_cols.last][0].id, :order => [:created_at]).as_json, :last_record_for_this_file => data_value.as_json,:errors=>errors}
  end
   
   
  def self.parse_sim_row(data_stream_id, row, site_id, data_col_array, variable_cols, sample_id, sample_type, sample_medium, sensor_col_array,sensor_cols, user,filename, timestamp)
     #require 'chronic'  #for robust timestamp parsing
      puts "INSIDE USER ID: #{user.id} ********************************"
     name = 2
     variable = 0
     sensor = 0
     unit = 1
     errors = ""
     result_ids = Array.new
     begin
     #Voeis::SensorValue.transaction do
     #timestamp = (data_timestamp_col == "") ? Time.parse(row[date_col].to_s + ' ' + row[time_col].to_s).strftime("%Y-%m-%dT%H:%M:%S%z") : row[data_timestamp_col.to_i]
     # vertical_offset = vertical_offset_col == "" ? 0.0 : row[vertical_offset_col.to_i].to_f
     #      end_vertical_offset = end_vertical_offset_col == "" ? 0.0 : row[end_vertical_offset_col.to_i].to_f
     data_stream = Voeis::DataStream.get(data_stream_id)
     # if DateTime.parse(row[data_timestamp_col])
     #        sample_datetime = DateTime.parse(row[data_timestamp_col])
     #      else
     #        sample_datetime = Chronic.parse(row[data_timestamp_col]).to_datetime
     #      end
     # timestamp = DateTime.civil(sample_datetime.year,sample_datetime.month,
     #                sample_datetime.day,sample_datetime.hour,sample_datetime.min,
     #                sample_datetime.sec, (data_stream.utc_offset+dst_time)/24.to_r)
      #sample_datetime.change(:offset => "#{(data_stream.utc_offset+dst_time)}:00")

     #if t = Date.parse(timestamp) rescue nil?
     #if (Voeis::DataValue.first(:local_date_time => timestamp) & 

     if Voeis::DataValue.first(:datatype=>data_stream.type, :local_date_time=>timestamp, :site_id=> site_id, :variable_id => data_col_array[variable_cols[0]][variable].id).nil? || sample_id != -1
           created_at = updated_at = Time.now.strftime("%Y-%m-%dT%H:%M:%S%z")
           create_comment = "Created at #{created_at} by #{user.first_name} #{user.last_name} [#{user.login}]"
           row_values = []
           newsample_id = -1
            if sample_id != -1
               sample_value=[]
               sql = "INSERT INTO \"voeis_samples\" (\"sample_type\",\"material\",\"lab_sample_code\",\"local_date_time\",\"created_at\",\"updated_at\",\"updated_by\",\"updated_comment\") VALUES "
               sql << "('#{sample_type}', '#{sample_medium}','#{row[sample_id]}', '#{timestamp}','#{created_at}', '#{updated_at}', #{user.id},'#{create_comment}')"
               #sql << sample_value.join(',')
               sql << " RETURNING \"id\""
               sample_result = repository.adapter.execute(sql)
               newsample_id = sample_result.insert_id
            end
           (0..row.size-1).each do |i|
             if  data_col_array[i][name] != "SampleID" && data_col_array[i][name] != "Ignore"
                 cv = /^[-]?[\d]+(\.?\d*)(e?|E?)(\-?|\+?)\d*$|^[-]?(\.\d+)(e?|E?)(\-?|\+?)\d*$/.match(row[i]) ? row[i].to_f : -9999.0
                 row_values << "(#{cv.to_s}, '#{timestamp.to_s}', 0,FALSE, '#{row[i].to_s}', '#{created_at}', '#{updated_at}', #{user.id},'#{create_comment}', 0,'#{timestamp.utc.to_s}','false',0,#{data_col_array[i][variable].quality_control.to_f},'#{data_stream.type}', #{site_id},  #{data_col_array[i][variable].id},  '#{filename}', #{newsample_id} )"
               end #end if
           end #end loop
           
           if !row_values.empty?
             sql = "INSERT INTO \"#{self.storage_name}\" (\"data_value\",\"local_date_time\",\"vertical_offset\",\"published\",\"string_value\",\"created_at\",\"updated_at\",\"updated_by\",\"updated_comment\", \"utc_offset\",\"date_time_utc\", \"observes_daylight_savings\", \"end_vertical_offset\", \"quality_control_level\", \"datatype\", \"site_id\", \"variable_id\", \"filename\", \"sample_id\") VALUES "
             sql << row_values.join(',')
             sql << " RETURNING \"id\""
             result_ids = repository.adapter.select(sql)
             variable_sql = Array.new
             site_sql = Array.new
             data_stream_sql = Array.new
             source_sql = Array.new
             (0..result_ids.length-1).each do |i|
               variable_sql << "(#{result_ids[i]},#{data_col_array[variable_cols[i]][variable].id})"
               site_sql << "(#{result_ids[i]},#{site_id})"
               data_stream_sql <<  "(#{result_ids[i]},#{data_stream_id})"
               source_sql << "(#{result_ids[i]},#{source_id})"
             end
             sql = "INSERT INTO \"voeis_data_value_variables\" (\"data_value_id\",\"variable_id\") VALUES "
             sql << variable_sql.join(',')
             repository.adapter.execute(sql)
             sql = "INSERT INTO \"voeis_data_value_sites\" (\"data_value_id\",\"site_id\") VALUES "
             sql << site_sql.join(',')
             repository.adapter.execute(sql)
             sql = "INSERT INTO \"voeis_data_stream_data_values\" (\"data_value_id\",\"data_stream_id\") VALUES "
             sql << data_stream_sql.join(',')
             repository.adapter.execute(sql)
             sql = "INSERT INTO \"voeis_data_value_sources\" (\"data_value_id\",\"source_id\") VALUES "
             sql << source_sql.join(',')
             repository.adapter.execute(sql)

             if newsample_id != -1
               sql = "INSERT INTO \"voeis_data_value_samples\" (\"data_value_id\",\"sample_id\") VALUES "
               sql << (0..result_ids.length-1).collect{|i|
                 "(#{result_ids[i]},#{newsample_id})"
               }.join(',')
               repository.adapter.execute(sql)
               sql = "INSERT INTO \"voeis_sample_sites\" (\"sample_id\",\"site_id\") VALUES "
               sql << "(#{newsample_id},#{site_id})"
               repository.adapter.execute(sql)
               sql = "INSERT INTO \"voeis_sample_variables\" (\"sample_id\",\"variable_id\") VALUES "
               sql << (0..result_ids.length-1).collect{|i|
                 "(#{newsample_id},#{data_col_array[variable_cols[i]][variable].id})"
               }.join(',')
               repository.adapter.execute(sql)
             else
                sql = "INSERT INTO \"voeis_data_value_sensor_types\" (\"data_value_id\",\"sensor_type_id\") VALUES "
                sql << (0..result_ids.length-1).collect{|i|
                  "(#{result_ids[i]},#{sensor_col_array[sensor_cols[i]][sensor].id})"
                }.join(',')
                repository.adapter.execute(sql)
            end
         end#end if

     end
     rescue Exception => e
       errors = "Row: #{row} - - did not store correclty.  ERROR:#{e}"
     end
     return {:result_ids => result_ids, :errors => errors}
  end
end
