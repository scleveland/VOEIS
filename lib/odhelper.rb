module Odhelper
  def self.default_repository_name
    :his
  end
  
  def upgrade_projects
    User.current = User.first
    DataMapper::Model.descendants.each do |model|
      begin
        model::Version
      rescue
      end
    end
    Project.all.each do |project|
      project.managed_repository do
        puts project.name

        DataMapper::Model.descendants.each do |model|
          begin
            model.auto_upgrade!
          rescue => e
            puts model.name+": #{e}"
          end
        end
      end
    end
    DataMapper.auto_upgrade!
  end
  
  # def add_created_at_postgres
  #   DataMapper::Model.descendants.each do |model|
  #     begin
  #       sql = "ALTER TABLE #{model.storage_name} ALTER COLUMN created_at DROP NOT NULL"
  #       repository.adapter.execute(sql)
  #     rescue
  #     end
  #   end
  #   Project.all.each do |project|
  #     project.managed_repository do
  #       puts project.name
  #       DataMapper::Model.descendants.each do |model|
  #         begin
  #           sql = "ALTER TABLE #{model.storage_name} ALTER COLUMN created_at DROP NOT NULL"
  #           repository.adapter.execute(sql)
  #         rescue => e
  #           puts model.name+": #{e}"
  #         end
  #       end
  #     end
  #   end
  # end
  
  def auto_migrate_versions
    DataMapper::Model.descendants.each do |model|
      begin
        model::Version.auto_migrate!
      rescue
      end
    end
    Project.all.each do |project|
      project.managed_repository do
        puts project.name

        DataMapper::Model.descendants.each do |model|
          begin
            model::Version.auto_migrate!
          rescue => e
            puts model.name+": #{e}"
          end
        end
      end
    end
    up  DataMapper.auto_upgrade!
  end
  
  
  
  def fix_scientific_data(project)
    project.managed_repository do
      Voeis::SensorValue.all(:value => -9999.0).each do |val|
        if /^[-]?[\d]+(\.?\d*)(e?|E?)(\-?|\+?)\d*$|^[-]?(\.\d+)(e?|E?)(\-?|\+?)\d*$/.match(val.string_value)
          val.value = val.string_value.to_f
          val.save
        end
      end
    end
  end
  
  def load_his_site_data (project, site, his_site, site_variables)
    #create a new data_stream
      #his_site = His::Site.first(:site_code => site.code)
      puts his_site
      if !his_site.nil?
        @site_data_stream = project.managed_repository{Voeis::DataStream.first_or_create(:name => site.code+'_HIS_legacy', :start_line => -9999, :filename => "NA")}
        #site_variables = His::DataValue.all(:site_id => his_site.id).all(:fields => [:variable_id], :unique => true)
        #site_variables = His::Variable.all
        site_variables.each do |var|
          #create a variable
          #puts @his_var = His::Variable.get(var.id)
          @project_var = project.managed_repository{Voeis::Variable.store_from_his(var)}
          #create a data_column
          @data_column =""
          puts "before First"
          first_val = His::DataValue.first(:site_id => his_site.id, :variable_id => var.id)
          if first_val.nil?
            #do nothing
          else
            puts "inside"
            project.managed_repository do
              puts @data_column = Voeis::DataStreamColumn.create(
                :column_number => -9999,
                :name => @project_var.variable_code,
                :type => "Legacy",
                :unit => "NA",
                :original_var => "Legacy")
              @data_column.data_streams << @site_data_stream
              @data_column.variables << @project_var
              @data_column.save!
            end
            #create a sensor_type
            @sensor_type =""
            project.managed_repository do
              puts @sensor_type = Voeis::SensorType.create(
                            :name => @project_var.variable_name + @site.name,
                            :min => 0.0,
                            :max => 0.0,
                            :difference => 0.0)
              #Add sites and variable associations to senor_type
              @sensor_type.sites << site
              @sensor_type.variables <<  @project_var
              @sensor_type.data_stream_columns << @data_column
              @sensor_type.save!
              site.variables << project_var
              site.save!
            end
            #create all the sensor_values
            # 
            @his_unit = His::Unit.get(@project_var.variable_units_id)
            @unit = ""
            parent.managed_repository do
              @unit = Voeis::Unit.first_or_create(
                :units_name => @his_unit.units_name, 
                :units_type => @his_unit.units_type, 
                :units_abbreviation =>@his_unit.units_abbreviation)
              @unit.variables << @project_var
              @unit.save!
            end
            end_time = His::DataValue.last(:site_id => site.id, :variable_id => var.id, :order => [:local_date_time.asc]).local_date_time
            start_time = Time.now - 2000.year
            while start_time != end_time
              His::DataValue.all(:site_id => site.id, :variable_id => var.id, :local_date_time.gte => start_time, :limit => 10).each do |val|
                #create sensor value
                #associate with site
                #associate with sensor_type
                #associate with data_columns
                #associate with variable
                parent.managed_repository do
                  puts sensor_value = Voeis::SensorValue.new(
                    :value => val.data_value,
                    :units => @unit.units_name,
                    :timestamp => val.local_date_time,
                    :published => true,
                    :string_value => val.data_value.to_s)
                  logger.info {sensor_value.valid?}
                  logger.info{sensor_value.errors.inspect()}
                  sensor_value.save!
                  logger.info{sensor_type_array[i].id}
                  sensor_value.sensor_type << @sensor_type
                  sensor_value.site << site
                  sensor_value.variables << @project_var
                  sensor_value.save!
                  start_time = val.local_date_time
                end #end manged_repo
              end #each |val|
            end #while
          end #end if first_val
        end #each |var|
      end #if
  end #def
  
  
  
  def search_to_ruport
    p = Project.first
    r = Array.new
    p.managed_repository{Voeis::SensorValue.properties.map{|k| r << k.name}}
    csv = r.to_csv + p.managed_repository{Voeis::SensorValue.all(:id.gt => 130100).to_csv}
    File.open("my_temp.csv", 'w'){|f| f.write(csv)}
    csv_data = CSV.read "my_temp.csv"
    headers = csv_data.shift.map{|i| i.to_s}
    string_data = csv_data.map{|row| row.map{|cell| cell.to_s} }
    table = Ruport::Data::Table.new :data=> string_data, :column_names => headers
    table.pivot 'sensor_id', :group_by => "timestamp", :values => "string_value"
    
    
    
    
  end
  
  def create_data_report
    report = ""
    
    Project.all.each do |p|
      if p.managed_repository{Voeis::SensorValue.count} != 0
        puts '**************************'
        puts p.name
        report = report + "<div><b>Project: " + p.name + "</b><br/><div>"
        p.managed_repository{Voeis::Site.all}.each do |s|
          report = report + s.name + "<br/>"
          report = report + "<table><tr><th>Variable Name</th><th>Variable ID</th><th>Data StartDate</th><th>Data EndDate</th><th>Total Number of Records</tr>"
          s.sensor_types.all.each do |st|
            v = st.variables.first
            if st.sensor_values.count != 0
              report = report + "<tr><td>"+v.variable_name+"</td><td>"+v.id.to_s+"</td><td>"+st.sensor_values.first(:order => [:timestamp]).timestamp.to_s+"</td><td>"+st.sensor_values.last(:order => [:timestamp]).timestamp.to_s+"</td><td>"+st.sensor_values.count.to_s+"</td></tr>"
            else
              report = report + "<tr><td>"+v.variable_name+"</td><td>"+v.id.to_s+"</td><td></td><td></td><td></td></tr>"
            end  
          end  
          report = report + "</table>"
          puts s.name
        end
        report =report + "</div>"
      end
      report =report + "</div>"
    end
  end
  
  def move_project_sensor_values_to_data_values(project)
    sites = project.managed_repository{Voeis::Site.all}
    sites.each do |site|
      site.data_streams.each do |data_stream|
        #select all sensor_values related to the site and variable
        data_stream_id = data_stream.id
        data_stream.data_stream_columns.each do |dcol|
          row_values = Array.new
          if !dcol.sensor_types.first.nil?
            var = dcol.sensor_types.first.variables.first
            sensor_type = project.managed_repository{Voeis::SensorType.get(dcol.sensor_types.first.id)}
            (sensor_type.sensor_values.all(:moved => nil)).each do |val|
              row_values << "(#{val.value}, '#{val.timestamp}', #{val.vertical_offset},FALSE, '#{val.string_value}', '#{val.created_at}', '#{val.updated_at}', #{val.timestamp.utc_offset/(60*60) },'#{val.timestamp.utc}',FALSE,NULL,#{val.quality_control_level}, '#{data_stream.type}' )"
              val.moved = true
              val.save
            end             
            if !row_values.empty?
              sql = "INSERT INTO \"voeis_data_values\" (\"data_value\",\"local_date_time\",\"vertical_offset\",\"published\",\"string_value\",\"created_at\",\"updated_at\", \"utc_offset\",\"date_time_utc\", \"observes_daylight_savings\", \"end_vertical_offset\", \"quality_control_level\", \"type\") VALUES "
              sql << row_values.join(',')
              sql << " RETURNING \"id\""
              result_ids = project.managed_repository{repository.adapter.select(sql)}
              sql = "INSERT INTO \"voeis_data_value_variables\" (\"data_value_id\",\"variable_id\") VALUES "
              sql << (0..result_ids.length-1).collect{|i|
                "(#{result_ids[i]},#{var.id})"
              }.join(',')
              project.managed_repository{repository.adapter.execute(sql)}
              sql = "INSERT INTO \"voeis_data_value_sites\" (\"data_value_id\",\"site_id\") VALUES "
              sql << (0..result_ids.length-1).collect{|i|
                "(#{result_ids[i]},#{site.id})"
              }.join(',')
              project.managed_repository{repository.adapter.execute(sql)}
              sql = "INSERT INTO \"voeis_data_stream_data_values\" (\"data_value_id\",\"data_stream_id\") VALUES "
              sql << (0..result_ids.length-1).collect{|i|
                "(#{result_ids[i]},#{data_stream_id})"
              }.join(',')
              project.managed_repository{repository.adapter.execute(sql)}
              sql = "INSERT INTO \"voeis_data_value_sensor_types\" (\"data_value_id\",\"sensor_type_id\") VALUES "
              sql << (0..result_ids.length-1).collect{|i|
                 "(#{result_ids[i]},#{sensor_type.id})"
              }.join(',')
              project.managed_repository{repository.adapter.execute(sql)}
            end
          end
        end
      end
    end###
  end
  
  def move_sensor_values_to_data_values
    Project.all.each do |project|
      move_project_sensor_values_to_data_values(project)
    end  
  end
  
  def set_data_values_type
    Project.all.each do |project|
      project.managed_repository do
        sql ="UPDATE voeis_data_values SET type = 'Sample' WHERE type IS NULL"
        repository.adapter.execute(sql)
      end
    end 
  end
  
  def set_project_data_stream_source(source, project)
    @source = source
    @project_source = nil
    project.managed_repository do
      @project_source = Voeis::Source.first_or_create(:organization => @source.organization,      
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
      Voeis::DataStream.all.each do |data_stream|
        if data_stream.source.nil?
          data_stream.source = @project_source
          data_stream.save
        end
      end
    end
  end
  
  v =Voeis::Source.create(
                        :organization => "Unknown",      
                        :source_description => "Unknown",
                        :source_link => "Unknown",       
                        :contact_name => "Unknown",      
                        :phone => "Unknown",             
                        :email =>"Unknown@n.com",             
                        :address => "Unknown",           
                        :city => "Unknown",              
                        :state => "Unknown",             
                        :zip_code => "Unknown",          
                        :citation => "Unknown",          
                        :metadata_id => 0)
  
  def set_data_stream_source(source_id)
    @source = Voeis::Source.get(source_id)
    Project.all.each do |project|
      set_project_data_stream_source(@source, project) 
    end
  end
  
  # sql ="SELECT * FROM voeis_data_values WHERE type IS NULL LIMIT 1"
  # results =repository.adapter.select(sql)
end


# 
# DataMapper::Model.descendants.each do |model|
#   begin
#     model::Version
#   rescue
#   end
# end
# Project.all.each do |project|
#   project.managed_repository do
#     puts project.name
# 
#     DataMapper::Model.descendants.each do |model|
#       begin
#         model.all.each do |m|
#           m.updated_at = m.created_at
#           m.save!
#         end
#         model.auto_upgrade!
#       rescue => e
#         puts model.name+": #{e}"
#       end
#     end
#   end
# end
# DataMapper.auto_upgrade!
