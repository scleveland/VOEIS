module Odhelper
  def self.default_repository_name
    :his
  end
  
  def upgrade_sites_CVzero
    # REPLACE ALL CV REFERENCES: null -> 0
    # Fields ending _id that are NOT references
    #ID_EXCEPTIONS = ['his_id']
    User.current = User.first
    Project.all.each do |project|
      print '>>>PROJECT: '+project.name
      project.managed_repository do
        Voeis::Site.all.each do |site|
          if !site.nil?
            site.lat_long_datum_id = 0 if site.lat_long_datum_id.nil?
            site.vertical_datum_id = 0 if site.vertical_datum_id.nil?
            site.local_projection_id = 0 if site.local_projection_id.nil?
            if site.attribute_dirty?(:lat_long_datum_id) or
              site.attribute_dirty?(:vertical_datum_id) or
              site.attribute_dirty?(:local_projection_id)
              siteId = [project.id,site.id,site.name]
              if site.save
                puts 'SITE UPDATED: ProjID: %s -- SiteID: %s (%s)'%siteId
              else
                puts '!!!SAVE FAILED: ProjID: %s -- Site ID: %s (%s)'%siteId
              end
            end
          end
        end
      end
    end
  end
  
  def upgrade_sites_CVnull
    # REPLACE ALL CV REFERENCES: null -> 0
    # Fields ending _id that are NOT references
    #ID_EXCEPTIONS = ['his_id']
    User.current = User.first
    Project.all.each do |project|
      print '>>>PROJECT: '+project.name
      project.managed_repository do
        Voeis::Site.all.each do |site|
          if !site.nil?
            site.lat_long_datum_id = nil if site.lat_long_datum_id==0
            site.vertical_datum_id = nil if site.vertical_datum_id==0
            site.local_projection_id = nil if site.local_projection_id==0
            if site.attribute_dirty?(:lat_long_datum_id) or
              site.attribute_dirty?(:vertical_datum_id) or
              site.attribute_dirty?(:local_projection_id)
              siteId = [project.id,site.id,site.name]
              if site.save
                puts 'SITE UPDATED: ProjID: %s -- SiteID: %s (%s)'%siteId
              else
                puts '!!!SAVE FAILED: ProjID: %s -- Site ID: %s (%s)'%siteId
              end
            end
          end
        end
      end
    end
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
  
  def upgrade_project(project)
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
      puts "SITE: "+site.name
      site.data_streams.each do |data_stream|
        #select all sensor_values related to the site and variable
        puts "DATASTREAM: "+ data_stream.name
        data_stream_id = data_stream.id
        source = data_stream.source
        data_stream.data_stream_columns.each do |dcol|
          row_values = Array.new
          if !dcol.sensor_types.first.nil?
            var = dcol.sensor_types.first.variables.first
            sensor_type = project.managed_repository{Voeis::SensorType.get(dcol.sensor_types.first.id)}
            puts "SENSOR: "+sensor_type.name
            (sensor_type.sensor_values.all(:moved => nil)).each do |val|
              print val.id.to_s + ','
              STDOUT.flush
              row_values << "(#{val.value}, '#{val.timestamp}', #{val.vertical_offset},FALSE, '#{val.string_value}', '#{val.created_at}', '#{val.updated_at}', #{val.timestamp.utc_offset/(60*60) },'#{val.timestamp.utc}',FALSE,NULL,#{val.quality_control_level}, '#{data_stream.type}' )"
              # val.moved = true
              # puts "Before Save"
              # puts row_values[0]
              # val.save
              # puts "AFTER save"
              sql = "UPDATE voeis_sensor_values SET moved = true WHERE id = #{val.id}"
              project.managed_repository{repository.adapter.execute(sql)}
            end             
            puts "STORING VALUES"
            if !row_values.empty?
              sql = "INSERT INTO \"voeis_data_values\" (\"data_value\",\"local_date_time\",\"vertical_offset\",\"published\",\"string_value\",\"created_at\",\"updated_at\", \"utc_offset\",\"date_time_utc\", \"observes_daylight_savings\", \"end_vertical_offset\", \"quality_control_level\", \"datatype\") VALUES "
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
              begin
              sql = "INSERT INTO \"voeis_data_value_sources\" (\"data_value_id\",\"source_id\") VALUES "
              sql << (0..result_ids.length-1).collect{|i|
                "(#{result_ids[i]},#{source.id})"
              }.join(',')
              repository.adapter.execute(sql)
              rescue
                puts "Problem STORING SOURCE*****************"
              end
            puts "DONE STORING VALUES"
            end
          end
        end
      end
    end###
  end
  
  def move_sensor_values_to_data_values
    Project.all.each do |project|
      puts "PROJECT: " + project.name
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
  
  def set_project_data_stream_source(project)
    #@source = source
    @project_source = nil
    project.managed_repository do
      @project_source = Voeis::Source.first(
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
      Voeis::DataStream.all.each do |data_stream|
        unless data_stream.source
          data_stream.source = @project_source
          data_stream.save
        end
      end
    end
  end
  def set_created_at 
    today = Time.now
    DataMapper::Model.descendants.each do |model|
      begin
        sql = "UPDATE #{model.storage_name} SET created_at = now() WHERE created_at IS NULL"
        results  = repository.adapter.execute(sql)
      rescue  => e
        puts model.name+": #{e}"
      end
      begin
       sql = "UPDATE #{model::Version.storage_name} SET created_at = now() WHERE created_at IS NULL"
       repository.adapter.execute(sql)
      rescue  => e
         puts model.name+": #{e}"
       end
    end
    Project.all.each do |project|
      project.managed_repository do
        puts project.name
        DataMapper::Model.descendants.each do |model|
          begin
            sql = "UPDATE #{model.storage_name} SET created_at = now() WHERE created_at IS NULL"
            repository.adapter.execute(sql)
          rescue => e
            puts model.name+": #{e}"
          end
          begin
            sql = "UPDATE #{model::Version.storage_name} SET created_at = now() WHERE created_at IS NULL"
            repository.adapter.execute(sql)
           rescue  => e
              puts model.name+": #{e}"
           end
        end
      end
    end
   end
  
  
  def set_updated_at 
   today = Time.now
   DataMapper::Model.descendants.each do |model|
     begin
       sql = "UPDATE #{model.storage_name} SET updated_at = now() WHERE updated_at IS NULL"
       results  = repository.adapter.execute(sql)
     rescue  => e
       puts model.name+": #{e}"
     end
     begin
      sql = "UPDATE #{model::Version.storage_name} SET updated_at = now() WHERE updated_at IS NULL"
      repository.adapter.execute(sql)
     rescue  => e
        puts model.name+": #{e}"
      end
   end
   Project.all.each do |project|
     project.managed_repository do
       puts project.name
       DataMapper::Model.descendants.each do |model|
         begin
           sql = "UPDATE #{model.storage_name} SET updated_at = now() WHERE updated_at IS NULL"
           repository.adapter.execute(sql)
         rescue => e
           puts model.name+": #{e}"
         end
         begin
           sql = "UPDATE #{model::Version.storage_name} SET updated_at = now() WHERE updated_at IS NULL"
           repository.adapter.execute(sql)  
          rescue  => e
             puts model.name+": #{e}"
          end
       end
     end
   end
  end
  
  def set_data_stream_source
    Project.all.each do |project|
      puts project.name
      begin
        set_project_data_stream_source(project) 
      rescue Exception => e
        puts project.name + " had a proplem:" + e.message
      end
    end
  end
  
  def slow_set_site_and_variables(project)
    project.managed_repository do
      Voeis::Site.each do |site|
        puts site.name
        site.variables.each do |var|
          puts site.name + ':' + var.variable_name
          var.data_values.all.update!(:site_id => site.id, :variable_id => var.id)
        end
      end
    end
  end
  
  def set_site_and_variables(project)
    project.managed_repository do
      Voeis::Site.each do |site|
        puts site.name
        site.variables.each do |var|
          puts site.name + ':' + var.variable_name
          set_data_values_site_and_variable(site.id, var.id)
        end
      end
    end
  end
  
  def set_data_stream_utc_offsets(project)
    project.managed_repository do
      Voeis::DataStream.all.each do |data_stream_template|
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
      end
    end
  end
  
  def set_project_sites_time_zone_offset(project)
    project.managed_repository do
      Voeis::Site.all.each do |site|
        if site.time_zone_offset == "unknown" || site.time_zone_offset == "unkown" || site.time_zone_offset.nil?
          begin
            site.fetch_time_zone_offset
          rescue
            puts "site utc offset fectch"
          end
        end
      end
    end
  end
  
  def set_data_values_site_and_variable(site_id, variable_id)
    site = Voeis::Site.get(site_id)
    variable = Voeis::Variable.get(variable_id)
    (site.data_values.all(:site_id => nil) & variable.data_values.all(:site_id=>nil)).all.update!(:site_id => site.id, :variable_id => variable.id)
  end
  
  def set_sites(project)
    project.managed_repository do
      Voeis::Site.all.each do |site|
        if site.data_values.count > 0
          sql = "SELECT data_value_id FROM voeis_data_value_sites WHERE site_id = #{site.id}"
          results = repository.adapter.select(sql)
          sql ="UPDATE voeis_data_values SET site_id = #{site.id} WHERE  "
          sql << (0..results.length-1).collect{|i|
            "id = #{results[i]}"
          }.join(' OR ')
         results = repository.adapter.execute(sql)
        end
      end
    end
  end
  
  def set_variables(project)
    project.managed_repository do
      Voeis::Variable.all.each do |var|
        if var.data_values.count > 0
          sql = "SELECT data_value_id FROM voeis_data_value_variables WHERE variable_id = #{var.id}"
          @results = repository.adapter.select(sql)
          hundreth = (@results.length/100).to_i
          (0..9).each do |c|
            start_id = (c*hundreth)
            end_id = start_id + hundreth-1
            sql ="UPDATE voeis_data_values SET variable_id = #{var.id} WHERE "
            sql << (start_id..end_id).collect{|i|
              "id = #{@results[i]}"
            }.join(' OR ')
            begin
              results = repository.adapter.execute(sql)
            rescue => e
              puts e
            end
          end
        end
      end
    end
  end
  
  def create_data_value_site_and_variable_index(project)
    project.managed_repository do
      begin
        # sql = "CREATE INDEX data_value_idx ON voeis_data_values (datatype, local_date_time, site_id, variable_id)"
        # repository.adapter.execute(sql)
        sql = "CREATE INDEX data_value_idx_var ON voeis_data_values (variable_id)"
        repository.adapter.execute(sql)
        sql = "CREATE INDEX data_value_idx_site ON voeis_data_values (site_id)"
        repository.adapter.execute(sql)
        sql = "CREATE INDEX data_value_idx_site_var ON voeis_data_values (site_id, variable_id)"
        repository.adapter.execute(sql)
        sql = "CREATE INDEX data_value_idx_time ON voeis_data_values (local_date_time)"
        repository.adapter.execute(sql)
        sql = "CREATE INDEX data_value_idx_site_var_time ON voeis_data_values (local_date_time, site_id, variable_id)"
        repository.adapter.execute(sql)
        sql = "CREATE INDEX data_value_idx_type ON voeis_data_values (datatype)"
        repository.adapter.execute(sql)
      rescue
      end
    end
  end
  
  def create_site_data_catalog_index(project)
    project.managed_repository do
      sql = "CREATE INDEX site_data_catalog_idx_site_var ON voeis_data_values (site_id, variable_id)"
      repository.adapter.execute(sql)
      sql = "CREATE INDEX site_data_catalog_idx_site ON voeis_data_values (site_id)"
      repository.adapter.execute(sql)
    end
  end
  
  def set_local_variable_id_to_global(project)
    puts project.name
    variables = Voeis::Variable.all
    project.managed_repository do
      Voeis::Variable.all.each do |var|
        begin
          old_id = var.id
          puts old_id
          g_var = variables.first(:variable_code => var.variable_code)
          puts g_var.id
          if g_var.nil?
            puts "Oh no can't find code!"
          elsif old_id == g_var.id
            puts "Oh I'm already Done with that Variable"
          else
            new_id = g_var.id
            # begin
              var.attributes = g_var.attributes
              var.id = g_var.id
              var.save!
            # rescue Exception => e  
            #   puts var.variable_name + ':' + var.variable_code+ ":" +var.id.to_s+'|'+old_id.to_s+" - - did not want to save - continueing as if it did in case one variable has been assigned multiple times! #{e.message}"
            # end
            sql = "UPDATE voeis_data_stream_column_variables SET variable_id = #{new_id.to_s} WHERE variable_id = #{old_id.to_s}"
            repository.adapter.execute(sql)
            sql = "UPDATE voeis_data_value_variables SET variable_id = #{new_id.to_s} WHERE variable_id = #{old_id.to_s}"
            repository.adapter.execute(sql)
            sql = "UPDATE voeis_data_values SET variable_id = #{new_id.to_s} WHERE variable_id = #{old_id.to_s}"
            repository.adapter.execute(sql)
            sql = "UPDATE voeis_site_variables SET variable_id = #{new_id.to_s} WHERE variable_id = #{old_id.to_s}"
            repository.adapter.execute(sql)
            sql = "UPDATE voeis_sample_variables SET variable_id = #{new_id.to_s} WHERE variable_id = #{old_id.to_s}"
            repository.adapter.execute(sql)
            sql = "UPDATE voeis_site_data_catalogs SET variable_id = #{new_id.to_s} WHERE variable_id = #{old_id.to_s}"
            repository.adapter.execute(sql)
            sql = "UPDATE voeis_unit_variables SET variable_id = #{new_id.to_s} WHERE variable_id = #{old_id.to_s}"
            repository.adapter.execute(sql)
            sql = "UPDATE voeis_sensor_type_variables SET variable_id = #{new_id.to_s} WHERE variable_id = #{old_id.to_s}"
            repository.adapter.execute(sql)
          end
        rescue Exception => e  
          puts var.variable_name + ": did not want to save! #{e.message}"
        end
      end
    end
  end
  

  def set_local_variable_id_to_global_with_continue(project)
    puts project.name
    variables = Voeis::Variable.all
    project.managed_repository do
      Voeis::Variable.all.each do |var|
        begin
          old_id = var.id
          puts old_id
          g_var = variables.first(:variable_code => var.variable_code)
          puts g_var.id
          if g_var.nil?
            puts "Oh no can't find code!"
          elsif old_id == g_var.id
            puts "Oh I'm already Done with that Variable"
          else
            new_id = g_var.id
            begin
              var.attributes = g_var.attributes
              var.id = g_var.id
              var.save!
            rescue Exception => e  
              puts var.variable_name + ':' + var.variable_code+ ":" +var.id.to_s+'|'+old_id.to_s+" - - did not want to save - continueing as if it did in case one variable has been assigned multiple times! #{e.message}"
            end
            sql = "UPDATE voeis_data_stream_column_variables SET variable_id = #{new_id.to_s} WHERE variable_id = #{old_id.to_s}"
            repository.adapter.execute(sql)
            sql = "UPDATE voeis_data_value_variables SET variable_id = #{new_id.to_s} WHERE variable_id = #{old_id.to_s}"
            repository.adapter.execute(sql)
            sql = "UPDATE voeis_data_values SET variable_id = #{new_id.to_s} WHERE variable_id = #{old_id.to_s}"
            repository.adapter.execute(sql)
            sql = "UPDATE voeis_site_variables SET variable_id = #{new_id.to_s} WHERE variable_id = #{old_id.to_s}"
            repository.adapter.execute(sql)
            sql = "UPDATE voeis_sample_variables SET variable_id = #{new_id.to_s} WHERE variable_id = #{old_id.to_s}"
            repository.adapter.execute(sql)
            sql = "UPDATE voeis_site_data_catalogs SET variable_id = #{new_id.to_s} WHERE variable_id = #{old_id.to_s}"
            repository.adapter.execute(sql)
            sql = "UPDATE voeis_unit_variables SET variable_id = #{new_id.to_s} WHERE variable_id = #{old_id.to_s}"
            repository.adapter.execute(sql)
            sql = "UPDATE voeis_sensor_type_variables SET variable_id = #{new_id.to_s} WHERE variable_id = #{old_id.to_s}"
            repository.adapter.execute(sql)
          end
        rescue Exception => e  
          puts var.variable_name + ": did not want to save! #{e.message}"
        end
      end
    end
  end
  
  def change_variable_no_data_value(project)
    project.managed_repository do
      sql ="ALTER TABLE voeis_variables ALTER COLUMN no_data_value TYPE varchar(512)"
      repository.adapter.execute(sql)
    end
  end
  def change_variable_no_data_value_global
    sql ="ALTER TABLE voeis_variables ALTER COLUMN no_data_value TYPE varchar(512)"
    repository.adapter.execute(sql)
  end
  
  def set_cv_types
    voeis_cv = Voeis::CVType.first(:name=>"VOEIS")
    Voeis::VariableNameCV.all.each do |vn|
      if vn.cv_types.empty?
        vn.cv_types << voeis_cv
        vn.save
      end
    end
    Voeis::SampleMediumCV.all.each do |sm|
      if sm.cv_types.empty?
        sm.cv_types << voeis_cv
        sm.save
      end
    end
    Voeis::ValueTypeCV.all.each do |sm|
      if sm.cv_types.empty?
        sm.cv_types << voeis_cv
        sm.save
      end
    end
    Voeis::DataTypeCV.all.each do |sm|
     if sm.cv_types.empty?
       sm.cv_types << voeis_cv
       sm.save
     end
    end
    Voeis::GeneralCategoryCV.all.each do |sm|
     if sm.cv_types.empty?
       sm.cv_types << voeis_cv
       sm.save
     end
    end
  end
  
  def set_variable_quality_control(project)
    puts project.name
    project.managed_repository do
      Voeis::Variable.all.each do |var|
        if var.quality_control.nil?
          puts var.variable_name
          var.quality_control = 0
          var.save!
        end
      end
    end
  end
  
  # def build_multi_variable_table(site_id, variables)
  #   project.managed_repository do
  #     qsql = "SELECT DISITINCT local_date_time FROME voeis_data_values WHERE local_date_time >= start_time AND local_date_time <= end_time AND site_id = site_id AND variable_id IN (VALUES"
  #     qsql_array = Array.new
  #     tsql_array = Array.new
  #     tsql = "CREATE TABLE this_search_id { local_date_time timestamp,"
  #     variables.each do |var|
  #       qsql_array << "(#{var.id})"
  #       tsql_array << "variable_#{var.id} integer"
  #     end
  #     tsql <<"#{tsql_array.join(',')} }"
  #     qsql <<"#{qsql_array.join(',')} )"
  #     
  #     UPDATE 
  #     #UPDATE owner SET picturemedium = dvds.picturemedium, title = dvds.title,
  #     #titleOrder = dvds.title, releasedate = CAST(dvds.releasedate AS date) FROM
  #     #(
  #     #        SELECT DISTINCT
  #     #        detail_dvd.asin,
  #     #        detail_dvd.picturemedium,
  #     #        detail_dvd.title,
  #     #        detail_dvd.releasedate
  #     #        FROM detail_dvd
  #     #        WHERE releasedate IS NOT NULL AND releasedate <> '' AND
  #     #(length(releasedate) = 10 OR length(releasedate) = 23)
  #     #)
  #     #AS dvds WHERE owner.asin = dvds.asin;
  # end
  
  # sql ="SELECT * FROM voeis_data_values WHERE type IS NULL LIMIT 1"
  # results =repository.adapter.select(sql)
end

#= javascript_include_tag("http://ajax.googleapis.com/ajax/libs/dojo/1.6.0/dojo/dojo.xd.js",'underscore.js','backbone.js','yogo/ui/MenuLink.js', 'yogo/maps/google.js', 'yogo/maps/google/Map.js', 'yogo/maps/google/DataMap.js','voeis/store/Projects.js','voeis/store/Sites.js','yogo/xhr/csrf','voeis/Server.js','voeis/Collection.js','voeis/model/Project.js', 'voeis/model/Site.js','dojo/store/JsonRest.js', 'voeis/maps/google/ProjectsMap.js','voeis/collection/Projects.js','voeis/collection/Sites.js','voeis/Model.js','voeis/ui/ProjectSitesGrid.js','voeis/ui/SitePane.js', 'voeis/ui/SitePane2.js')

# Project.all.each do |proj|
# 
#     Membership.first_or_create(:user => User.current, :project => proj, :role => Role.get(5))
#end