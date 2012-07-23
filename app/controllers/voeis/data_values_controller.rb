require 'responders/rql'

class Voeis::DataValuesController < Voeis::BaseController
  # Properly override defaults to ensure proper controller behavior
  # @see Voeis::BaseController
  responders :rql
  respond_to :html, :json
  defaults  :route_collection_name => 'data_values',
            :route_instance_name => 'data_value',
            :collection_name => 'data_values',
            :instance_name => 'data_value',
            :resource_class => Voeis::DataValue
  
  has_widgets do |root|
    root << widget(:versions)
    #root << widget(:data_value)
  end
  
  @project = parent
  
  
  #def new
  #end
  
  #def index
  #end
  
  def show
   @data_value=parent.managed_repository{Voeis::DataValue.get(params[:id].to_i)}
   @meta_tags = @data_value.meta_tags
   render :layout=>'data_value'
  end
  
  # DELETE /data_values/$ID$
  def destroy
    @project = parent
    @project.managed_repository{
      data_value = Voeis::DataValue.get(params[:id].to_i)
      data_value.destroy
      
      respond_to do |format|
        if data_value.destroy
          format.html{
            flash[:notice] = "DataValue was successfully Deleted."
            redirect_to project_url(@project)
          }
          format.json{
            render :json => {}.as_json, :callback => params[:jsoncallback]
          }
        end
      end
    }
  end
  
  # PUT /data_values/$ID$
  def update
    @project = parent
    @project.managed_repository{
      @data_value = Voeis::DataValue.get(params[:id].to_i)
      datparams = params[:data_value]
      
      logger.info '### DATPARAMS ###'
      logger.info datparams
      logger.info '### DATA VALUE ###'
      logger.info @data_value.to_hash
      
      datparams.each do |prop,value| 
        v = value.strip
        datparams[prop] = nil if v=='NaN' || v=='null'
      end
      ###
      tz = datparams[:local_date_time][19..-1]
      ###
      datparams[:local_date_time] = DateTime.parse(datparams[:local_date_time])
      datparams[:local_date_time].to_datetime.change(:offset => tz)  ### "#{utc_offset}:00")
      datparams[:date_time_utc] = DateTime.parse(datparams[:date_time_utc])
      datparams[:date_time_utc].to_datetime.change(:offset => "+00:00")
      [:data_value,:utc_offset].each{|prop| 
        datparams[prop] = datparams[prop].to_f }
      [:value_accuracy,:vertical_offset,:end_vertical_offset].each{|prop| 
        datparams[prop] = datparams[prop].blank? ? nil : datparams[prop].to_f }
      datparams[:quality_control_level] = datparams[:quality_control_level].to_i
      [:published,:observes_daylight_savings].each{|prop| 
        datparams[prop] = datparams[prop]=~(/(true|t|yes|y|1)$/i) ? true : false }

      datparams.each do |key, value|
        #@data_value[key] = value.blank? ? nil : value
        @data_value[key] = value
      end

      logger.info '### DATPARAMS UPDATED ###'
      logger.info datparams
      logger.info '### DATA VALUE UPDATED ###'
      logger.info @data_value.to_hash
      
      #logger.info '### READY TO SAVE VARIABLE ###'
      #logger.info @variable.to_hash
      debugger
      
      respond_to do |format|
        if @data_value.save
          format.html{
            flash[:notice] = "DataValue was Updated successfully."
            redirect_to project_url(@project)
          }
          format.json{
            render :json => @data_value.as_json, :callback => params[:jsoncallback]
          }
        end
      end

    }
    
  end
  
  #def create
  #end
  
  def meta_tags
    @data_value = @project.managed_repository{Voeis::DataValue.get(params[:id].to_i)}
  end
  
  def versions
    @tabId = params[:tab_id]
    @project = parent
    @data_value = @project.managed_repository{Voeis::DataValue.get(params[:id].to_i)}
    
    @versions = @project.managed_repository{@data_value.versions_array}
    @site = @project.managed_repository{Voeis::Site.get(@data_value.site_id.to_i)}
    @variable = @project.managed_repository{Voeis::Variable.get(@data_value.variable_id.to_i)}
    
    @data_refs = []
    temp = {}
    temp[:site] = "-none-"
    temp[:variable] = '-none-'
    #if !@site.nil?
    #  temp[:site] = "%s [Id:%s]"% @site.to_hash.values_at(:name,:id)
    #end
    #if !@variable.nil?
    #  temp[:variable] = "%s [Id:%s]"% @variable.to_hash.values_at(:variable_name,:id)
    #end
    temp[:published_string] = @data_value.published ? "YES" : "NO"
    temp[:vertical_offset_range] = "-none-"
    temp[:vertical_offset_range] = @data_value.vertical_offset.to_s if !@data_value.vertical_offset.nil?
    temp[:vertical_offset_range] += " - "+@data_value.end_vertical_offset.to_s if !@data_value.end_vertical_offset.nil?
    #temp[:datetime_string] = "-none-"
    temp[:datetime_string] = @data_value.local_date_time.strftime("%Y-%m-%d %H:%M:%S ")
    tz0 = @data_value.utc_offset.to_s.split('.')
    tz = (tz0[0][0]=='-' ? '-' : '+')+('00'+tz0[0].to_i.abs.to_s)[-2,2]+':'
    tz += tz0.count>1 ? ('0'+((('.'+tz0[1]).to_f*100).to_i*0.6).to_i.to_s)[-2,2] : '00'
    
    temp[:datetime_string] += tz+@data_value.date_time_utc.strftime(" [%Y-%m-%d %H:%M:%S UTC]")
    @data_refs << temp
    @versions.each{|ver| 
      temp = {}
      temp[:site] = "-none-"
      temp[:variable] = '-none-'
      #if !Voeis::Site.get(@data_value.site_id).nil?
      #  temp[:site] = "%s [Id:%s]"% Voeis::Site.get(@data_value.site_id).to_hash.values_at(:name,:id)
      #end
      #if !Voeis::Variable.get(@data_value.variable_id).nil?
      #  temp[:variable] = "%s [Id:%s]"% Voeis::Variable.get(@data_value.variable_id).to_hash.values_at(:variable_name,:id)
      #end
      temp[:published_string] = ver.published ? "YES" : "NO"
      temp[:vertical_offset_range] = "-none-"
      temp[:vertical_offset_range] = ver.vertical_offset.to_s if !@data_value.vertical_offset.nil?
      temp[:vertical_offset_range] += " - "+ver.end_vertical_offset.to_s if !ver.end_vertical_offset.nil?
      temp[:datetime_string] = ver.local_date_time.strftime("%Y-%m-%d %H:%M:%S ")
      tz0 = ver.utc_offset.to_s.split('.')
      tz = (tz0[0][0]=='-' ? '-' : '+')+('00'+tz0[0].to_i.abs.to_s)[-2,2]+':'
      tz += tz0.count>1 ? ('0'+((('.'+tz0[1]).to_f*100).to_i*0.6).to_i.to_s)[-2,2] : '00'
      temp[:datetime_string] += tz+ver.date_time_utc.strftime(" [%Y-%m-%d %H:%M:%S UTC]")
      @data_refs << temp
    }

    @ver_properties = [
#      {:label=>"Version", :name=>"version"},
      {:label=>"DataValue ID", :name=>"id"},
#      {:label=>"Site", :name=>"site"},
#      {:label=>"Variable", :name=>"variable"},
      {:label=>"Date/Time", :name=>"datetime_string", :contains=>["local_date_time","date_time_utc","utc_offset"]},
      {:label=>"Data Value", :name=>"data_value"},
      {:label=>"String Value", :name=>"string_value"},
      {:label=>"Data Origin", :name=>"datatype"},
      {:label=>"Value Accuracy", :name=>"value_accuracy"},
#      {:label=>"Date/Time", :name=>"datetime_local"},
#      {:label=>"UTC offset", :name=>"utc_offset"},
#      {:label=>"UTC Date/Time", :name=>"datetime_utc"},
      {:label=>"Vertical Offset", :name=>"vertical_offset_range", :contains=>["vertical_offset","end_vertical_offset"]},
#      {:label=>"Vertical Offset", :name=>"vertical_offset"},
#      {:label=>"End Vertical Offset", :name=>"end_vertical_offset"},
      {:label=>"Replicate", :name=>"replicate"},
      {:label=>"Q/C level", :name=>"quality_control_level"},
      {:label=>"Published", :name=>"published_string", :contains=>["published"]},
      {:label=>"File Name", :name=>"filename"}
#      {:label=>"Updated By", :name=>"updated_by_name"},
#      {:label=>"Update Comment", :name=>"updated_comment"},
#      {:label=>"Provenance Comment", :name=>"provenance_comment"}
      ]
    ###
  end
  
  ### BATCH UPDATE: SELECTED DataValues via Rscript or Rollback
  # (ajax/json)
  # @params['data_vals'] = array of DataValue IDs (optional, or 'data_set')
  # @params['data_set'] = a DataSet ID (optional, or 'data_vals')
  # @params['script'] = string - R-script to execute on DataValues (optional, or 'rollback')
  # @params['dryrun'] = don't save any DataValues if TRUE
  # @params['rollback'] = TRUE = ROLLBACK VERSION on batch (optional, or 'script')
  # @params['delete'] = TRUE = DELETE batch (optional, or 'script')
  # @params['target'] = variable_id ###-OR- target type: 'CSV' / etc.  (optional, or update self)
  ##def query_script_update
  def batch_update
    parent.managed_repository{
      updated = []
      data_val_ids = params['data_vals']
      dryrun = params['dryrun'].nil? || params['dryrun'] =~ /(false|f|no|0)/i || blank? ? false : true
      rollback = params['rollback'].nil? || params['rollback'] =~ /(false|f|no|0)/i || blank? ? false : true
      deletes = params['delete'].nil? || params['delete'] =~ /(false|f|no|0)/i || blank? ? false : true
      target = params['target']
      if(!target.nil?)
        target_var = target.to_i==0 ? false : target.to_i
        target_var = Voeis::Variable.get(target_var) if target_var
      end
      if data_set = Voeis::DataSet.get(params[:data_set].to_i)
        #data_values = data_set.data_values.map{|dv| dv.id}
        data_values = data_set.data_values
      else
        data_values = Voeis::DataValue.all(:id=>data_val_ids)
      end
      if deletes
        data_values.each{|data_value|
          dv = {:id=>data_value.id}
          if !data_value.destroy
            dv[:error] = 'ERROR: DELETE FAILED'
          else
            dv[:deleted] = 'DELETED!'
          end
          updated << dv
        }
        
      elsif rollback
        data_values.each{|data_value|
          dv = {:id=>data_value.id}
          if !data_value.rollback_version
            dv[:error] = 'ERROR: ROLLBACK FAILED'
          else
            dv[:rollback] = data_value.provenance_comment.match(/\d+$/).to_s
          end
          updated << dv
        }
      else
        rr = ::Rserve::Simpler.new
        data_values = data_values.all(:limit=>20) if dryrun
        dv_fields = ['data_value',
                      'string_value',
                      'utc_offset',
                      'datatype',
                      'replicate',
                      'value_accuracy',
                      'quality_control_level',
                      'vertical_offset',
                      'end_vertical_offset',
                      'published',
                      'variable_id']
        dv_fields_omit_update = []
        #CLEAN RSCRIPT!
        #HERE! - remove 'System' calls - etc
        rscript0 = params['script']
        rscript = ""
        script_show = ""
        rscript0.split(/\r\n|\n|\r/).each{|ln|
          rscript += ln+"\n" unless ln=~/system/i
          script_show += ln+"; " unless script_show.length>150
        }
        data_values.each{|data_value|
          #LOAD DV FIELDS
          dv = {:id=>data_value.id.to_i}
          provenance = []
          vars = {}
          err = ''
          dv_fields.each{|fld| vars[fld] = data_value[fld] }
          vars['date_string'] = data_value.local_date_time.iso8601.sub('T',' ').slice(0,19)
          #vars['date_string_utc'] = data_value.date_time_utc.iso8601.sub('T',' ').slice(0,19)
          todatetime = "date_time <- as.POSIXct(date_string)\n"
          #todatetime += "datetime_utc <- as.POSIXct(date_string_utc)\n"
          #EXECUTE SCRIPT
          begin
            rr.command(todatetime+rscript, vars)
          rescue Exception => e
            ###SYNTAX ERROR IN SCRIPT
            err = '*** SYNTAX ERROR!'
            dv['error'] = err
            updated << dv
            break
          end
          ###SAVE DV FIELDS
          #DEFAULT TARGET: UPDATE SELF
          new_data_value = data_value
          if target
            if target_var
              #NEW_DATA_VALUE AT TARGET_VAR
              begin
                new_data_var = Voeis::Variable.get(:id=>target_var)
              rescue Exception => e
                ###BAD TARGET VARIABLE
                err = '*** UNDEFINED TARGED VARIABLE!'
                dv['error'] = err
                updated << dv
                break
              end
              new_data_value = Voeis::DataValue.new(:variable_id=>target_var.id.to_i)
            elseif target=='CSV'
              #EXPORT TO CSV
              #new_data_value =
              
            elseif target=='XXX'
              #EXPORT TO XXX?
              #new_data_value =
              
            end
          end
          dv_fields.reject{|fld| dv_fields_omit_update.include?(fld) }.each{|fld| 
            #FIELD from R script
            updfld = rr>>fld
            #VALIDATION of fields
            updfld = updfld.nil? ? nil : ('%.8f' % updfld).to_f if fld=='data_value'
            updfld = updfld.nil? ? nil : ('%.6f' % updfld).to_f if ['value_accuracy','vertical_offset','end_vertical_offset'].include?(fld)
            if updfld!=data_value[fld] && (!target_var || fld!='variable_id')
              if !dryrun
                provenance << fld+'='+data_value[fld].to_s
                new_data_value[fld] = updfld
              end
              dv[fld] = updfld
            end
          }
          date_time_str = rr>>'format(date_time,"%Y-%m-%d %H:%M:%S")'
          date_time = DateTime.parse(date_time_str+('%+05.2f'%data_value.utc_offset).sub('.',''))
          if date_time.to_i!=data_value.local_date_time.to_i
            if !dryrun
              provenance << 'local_date_time='+data_value.local_date_time.to_s
              new_data_value['local_date_time'] = date_time
              #data_value.date_time_utc = DateTime.parse(rr>>'format(date_time_utc,"%Y-%m-%d %H:%M:%S")')
              new_data_value['date_time_utc'] = date_time-data_value.utc_offset.hours
            end
            dv['local_date_time'] = date_time_str
          end
          if !dryrun
            begin
              prov_comm = rr>>'provenance_comment'
            rescue Exception => e
              ### provenance_comment does not exist!
              prov_comm = 'VIA>> '+script_show
            end
            new_data_value['provenance_comment'] = 'SCRIPTED FROM: '+provenance.join('; ')+' -- '+prov_comm
            if err.blank? && !new_data_value.save
              err = '*** SAVE ERROR!'
            end
          end
          dv['error'] = err if !err.blank?
          updated << dv
        }
        rr.close
      end
      render :json=>updated.as_json, :callback=>params[:jsoncallback]
    }
  end
  
  
  # Gather information necessary to store sample data
  #
  #
  #
  # @author Sean Cleveland
  #
  # @api public
  def pre_process
    @project = parent
    @general_categories = Voeis::GeneralCategoryCV.all
  end
  
  # Gather information necessary to store samples and data
  #
  #
  #
  # @author Sean Cleveland
  #
  # @api public
  def pre_process_samples_and_data
    @project = parent
    @templates = parent.managed_repository{Voeis::DataStream.all(:type => "Sample")}
    @general_categories = Voeis::GeneralCategoryCV.all
  end

  # Gather information necessary to store samples and data
  #
  #
  #
  # @author Sean Cleveland
  #
  # @api public
  def pre_process_samples_file_upload
    @project = parent
    @data_templates = parent.managed_repository{Voeis::DataStream.all(:type => "Sample")}
    @general_categories = Voeis::GeneralCategoryCV.all
    @sites = parent.managed_repository{Voeis::Site.all}
  end

  # Gather information necessary to store samples and data
  #
  #
  #
  # @author Sean Cleveland
  #
  # @api public
  def pre_process_varying_samples_with_data
    @project = parent
    @templates = parent.managed_repository{Voeis::DataStream.all(:type => "Sample")}
    @general_categories = Voeis::GeneralCategoryCV.all
  end

  # Gather information necessary to store sample data
  #
  #
  #
  # @author Sean Cleveland
  #
  # @api public
  def pre_upload
     require 'csv_helper'
     @sites = parent.managed_repository{ Voeis::Site.all }
     @project = parent
     #@project = Project.first(:id => params[:project_id])
      @variables = Voeis::Variable.all
      @sites = parent.managed_repository{ Voeis::Site.all }
      @samples = parent.managed_repository{ Voeis::Sample.all }
      if !params[:datafile].nil? && datafile = params[:datafile]
        if ! ['text/csv', 'text/comma-separated-values', 'application/vnd.ms-excel',
              'application/octet-stream','application/csv'].include?(datafile.content_type)
          flash[:error] = "File type #{datafile.content_type} not allowed"
          redirect_to(:controller =>"voeis/data_values", :action => "pre_process", :params => {:id => params[:project_id]})

        else
          name = Time.now.to_s + params['datafile'].original_filename
          directory = "temp_data"
          @new_file = File.join(directory,name)
          File.open(@new_file, "wb"){ |f| f.write(params['datafile'].read)}
          
          @start_line = params[:start_line].to_i
          @start_row = get_row(@new_file, params[:start_line].to_i)
          @row_size = @start_row.size-1
          
          header_row = Array.new
          
          @var_array = Array.new
          @var_array[0] = ["","","","","","",""]
          @opts_array = Array.new
          @variables.all(:general_category => params[:general_category], :order => [:variable_name.asc]).each do |var|
            @opts_array << [var.variable_name+":"+var.sample_medium+':'+ var.data_type+':'+Voeis::Unit.get(var.variable_units_id).units_name, var.id.to_s]
          end
          if params[:start_line].to_i != 1
            header_row = get_row(@new_file, params[:start_line].to_i - 1)
          
            (0..@row_size).each do |i|
               @var_array[i] = [header_row[i],"","",opts_for_select(@opts_array),"","",""]
              end
          else
            (0..@row_size).each do |i|
              @var_array[i] = ["","","",opts_for_select(@opts_array),"","",""]
             end
          end
          
          #parse csv file into array
          @csv_array = Array.new
          csv_data = CSV.read(@new_file)
          i = @start_line
          csv_data[@start_line-1..-1].each do |row|
            @csv_array[i] = row.map! { |k| "#{k}" }.join(",")
            i = i + 1
          end
          @csv_size = i -1

      end
     end
  end
  
  # Gather information necessary to store samples and data
  #
  #
  #
  # @author Sean Cleveland
  #
  # @api public
  def pre_upload_samples_and_data
    require 'csv_helper'
     
    @project = parent
    @variables = Variable.all
    @sites = parent.managed_repository{ Voeis::Site.all }
    @samples = parent.managed_repository{ Voeis::Sample.all }
    @sample_types = Voeis::SampleTypeCV.all
    @sample_materials = Voeis::SampleMaterial.all
    @project_sample_materials = @project.managed_repository{Voeis::SampleMaterial.all}
    @lab_methods = @project.managed_repository{Voeis::LabMethod.all}
     
    #save uploaded file if possible
    if !params[:datafile].nil? && datafile = params[:datafile]
      if ! ['text/csv', 'text/comma-separated-values', 'application/vnd.ms-excel',
            'application/octet-stream','application/csv'].include?(datafile.content_type)
        flash[:error] = "File type #{datafile.content_type} not allowed"
        redirect_to(:controller =>"voeis/data_values", :action => "pre_process", :params => {:id => params[:project_id]})

      else
        #file can be saved
        name = Time.now.to_s + params['datafile'].original_filename
        directory = "temp_data"
        @new_file = File.join(directory,name)
        File.open(@new_file, "wb"){ |f| f.write(params['datafile'].read)}
        
        @start_line = params[:start_line].to_i
        #get the first row that has information in the CSV file
        @start_row = get_row(@new_file, params[:start_line].to_i)
        @row_size = @start_row.size-1
        
        @header_row = Array.new
        
        @var_array = Array.new
        @var_array[0] = ["","","","","","",""]
        @opts_array = Array.new
        @variables.all(:general_category => params[:general_category], :order => [:variable_name.asc]).each do |var|
          @opts_array << [var.variable_name+":"+var.sample_medium+':'+ var.data_type+':'+Unit.get(var.variable_units_id).units_name, var.id.to_s]
        end
        if params[:start_line].to_i != 1
          @header_row = get_row(@new_file, params[:start_line].to_i - 1)
        end
        @timestamp_column = ""
        @sample_column = ""
        @template_name = ""
        if params[:template] != "None"
            data_template = parent.managed_repository {Voeis::DataStream.first(:id => params[:template])}
            (0..@row_size).each do |i|
               puts i
               if !data_template.data_stream_columns.first(:column_number => i).nil?
                 data_col = data_template.data_stream_columns.first(:column_number => i)
                 if data_col.name != "Timestamp" && data_col.name != "SampleID"
                   if data_col.variables.empty?
                     @var_array[i] = [data_col.original_var, data_col.unit, data_col.type,opts_for_select(@opts_array),"", "", "",data_col.name]
                   else
                     @var_array[i] = [data_col.original_var, data_col.unit, data_col.type,opts_for_select(@opts_array,Variable.first(:variable_code => data_col.variables.first.variable_code).id.to_s),"", "", "",data_col.name]
                   end
                  else
                    @var_array[i] = [data_col.original_var, data_col.unit, data_col.type,opts_for_select(@opts_array),"","","",""]
                  end
                else
                  @var_array[i] = ["","","",opts_for_select(@opts_array),"","","",""]
                end
            end
            if !data_template.data_stream_columns.first(:name => "Timestamp").nil?
              @timestamp_column = data_template.data_stream_columns.first(:name => "Timestamp").column_number
            end
            @sample_column = data_template.data_stream_columns.first(:name => "SampleID").column_number
            @template_name = data_template.name
        else
          (0..@row_size).each do |i|
            @var_array[i] = ["","","",opts_for_select(@opts_array),"","",""]
           end
        end
 
        #parse csv file into array
        @csv_array = Array.new
        csv_data = CSV.read(@new_file)
        i = @start_line
        csv_data[@start_line-1..-1].each do |row|
          @csv_array[i] = row.map! { |k| "#{k}" }.join(",")
          i = i + 1
        end
        @csv_size = i -1

    end
   end
  end
  
  
  # Gather information necessary to store samples and data
  #
  #
  #
  # @author Sean Cleveland
  #
  # @api public
  def pre_upload_varying_samples_with_data
    require 'csv_helper'
     
    @project = parent
    @variables = Voeis::Variable.all
    @sites = parent.managed_repository{ Voeis::Site.all }
    @samples = parent.managed_repository{ Voeis::Sample.all }
    @sample_types = Voeis::SampleTypeCV.all
    @sample_materials = Voeis::SampleMaterial.all
    @project_sample_materials = @project.managed_repository{Voeis::SampleMaterial.all}
    @lab_methods = @project.managed_repository{Voeis::LabMethod.all}
     
    #save uploaded file if possible
    if !params[:datafile].nil? && datafile = params[:datafile]
      if ! ['text/csv', 'text/comma-separated-values', 'application/vnd.ms-excel',
            'application/octet-stream','application/csv'].include?(datafile.content_type)
        flash[:error] = "File type #{datafile.content_type} not allowed"
        redirect_to(:controller =>"voeis/data_values", :action => "pre_process", :params => {:id => params[:project_id]})

      else
        #file can be saved
        name = Time.now.to_s + params['datafile'].original_filename
        directory = "temp_data"
        @new_file = File.join(directory,name)
        File.open(@new_file, "wb"){ |f| f.write(params['datafile'].read)}
        
        @start_line = params[:start_line].to_i
        #get the first row that has information in the CSV file
        @start_row = get_row(@new_file, params[:start_line].to_i)
        @row_size = @start_row.size-1
        
        @header_row = Array.new
        
        @var_array = Array.new
        @var_array[0] = ["","","","","","",""]
        @opts_array = Array.new
        @variables.all(:general_category => params[:general_category], :order => [:variable_name.asc]).each do |var|
          @opts_array << [var.variable_name+":"+var.sample_medium+':'+ var.data_type+':'+Unit.get(var.variable_units_id).units_name, var.id.to_s]
        end
        if params[:start_line].to_i != 1
          @header_row = get_row(@new_file, params[:start_line].to_i - 1)
        end
        @timestamp_column = ""
        @sample_column = ""
        @template_name = ""
        if params[:template] != "None"
            data_template = parent.managed_repository {Voeis::DataStream.first(:id => params[:template])}
            (0..@row_size).each do |i|
               puts i
               if !data_template.data_stream_columns.first(:column_number => i).nil?
                 data_col = data_template.data_stream_columns.first(:column_number => i)
                 if data_col.name != "Timestamp" && data_col.name != "SampleID"
                   if data_col.variables.empty?
                     @var_array[i] = [data_col.original_var, data_col.unit, data_col.type,opts_for_select(@opts_array),"", "", "",data_col.name]
                   else
                     @var_array[i] = [data_col.original_var, data_col.unit, data_col.type,opts_for_select(@opts_array,Variable.first(:variable_code => data_col.variables.first.variable_code).id.to_s),"", "", "",data_col.name]
                   end
                  else
                    @var_array[i] = [data_col.original_var, data_col.unit, data_col.type,opts_for_select(@opts_array),"","","",""]
                  end
                else
                  @var_array[i] = ["","","",opts_for_select(@opts_array),"","","",""]
                end
            end
            if !data_template.data_stream_columns.first(:name => "Timestamp").nil?
              @timestamp_column = data_template.data_stream_columns.first(:name => "Timestamp").column_number
            end
            @sample_column = data_template.data_stream_columns.first(:name => "SampleID").column_number
            @template_name = data_template.name
        else
          (0..@row_size).each do |i|
            @var_array[i] = ["","","",opts_for_select(@opts_array),"","",""]
           end
        end
 
        #parse csv file into array
        @csv_array = Array.new
        csv_data = CSV.read(@new_file)
        i = @start_line
        csv_data[@start_line-1..-1].each do |row|
          @csv_array[i] = row.map! { |k| "#{k}" }.join(",")
          i = i + 1
        end
        @csv_size = i -1

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
  
  # Parses a csv file containing sample data values
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
   def parse_sample_data_csv(csv_file, data_stream_template, site)
     csv_data = CSV.read(csv_file)
     path = File.dirname(csv_file)
     sensor_type_array = Array.new
     data_stream_col = Array.new
     data_stream_template.data_stream_columns.each do |col|
       sensor_type_array[col.column_number] = parent.managed_repository{Voeis::SensorType.first(:name => col.original_var + site.name)}
       data_stream_col[col.column_number] = col
     end
     data_timestamp_col = data_stream_template.data_stream_columns.first(:name => "Timestamp").column_number
     csv_data[data_stream_template.start_line..-1].each do |row|
       (0..row.size-1).each do |i|
         if i != data_timestamp_col
           puts data_stream_col
           if data_stream_col[i].name != "ignore"
             #save to sensor_value and sensor_type
             parent.managed_repository{
             sensor_value = Voeis::SensorValue.new(
                                           :value => row[i],
                                           :units => data_stream_col[i].unit,
                                           :timestamp => row[data_timestamp_col],
                                           :published => false)
             sensor_value.save
             sensor_value.sensor_type << sensor_type_array[i]
             sensor_value.site << site
             sensor_value.save}
          end
         end
       end
     end
   end
   
   
   
   # Parses a csv file containing samples and data values
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
    def store_varying_samples_with_data

      data_stream =""
      site = parent.managed_repository{Voeis::Site.first(:id => params[:site])}
      redirect_path =Hash.new
      if params[:no_save] != "no"
        #create a parsing template
        #create and save new DataStream
        parent.managed_repository do
          data_stream = Voeis::DataStream.create(:name => params[:template_name],
            :description => "NA",
            :filename => params[:datafile],
            :start_line => params[:start_line].to_i,
            :type => "Sample")
          #Add site association to data_stream
          #
          data_stream.sites << site
          data_stream.save
        end
        @timestamp_col = -1
        range = params[:row_size].to_i
        (0..range).each do |i|
          #create the Timestamp column
          if i == params[:timestamp_col].to_i && params[:timestamp_col] != "None"
            #puts params["column"+i.to_s]
            @timestamp_col = params[:timestamp_col].to_i
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
          elsif i == params[:sample_id].to_i
            @sample_col = params[:sample_id].to_i
             parent.managed_repository do
               data_stream_column = Voeis::DataStreamColumn.create(
                                     :column_number => i,
                                     :name => "SampleID",
                                     :type =>"SampleID",
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
                                    :type =>         "NA")
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
              else
                data_stream_column.name = "ignore"
                data_stream_column.data_streams << data_stream
                data_stream_column.save
              end #end if
            end #end managed repository
          end #end if
        end #end range.each
        @sample_col = params[:sample_id].to_i
      else #use the existing template
        data_stream = parent.managed_repository{Voeis::DataStream.first(:name => params[:template_name])}
        if !data_stream.data_stream_columns.first(:name => "Timestamp").nil?
          @timestamp_col = data_stream.data_stream_columns.first(:name => "Timestamp").column_number
        else
          @timestamp_col = -1
        end
        @sample_col = data_stream.data_stream_columns.first(:name => "SampleID").column_number
      end #end if 'no_save'
      range = params[:row_size].to_i
      #store all the Variables in the managed repository
      @col_vars = Array.new
      (0..range).each do |i|
         @var = Variable.get(params["column"+i.to_s])
         parent.managed_repository do
           if !params["ignore"+i.to_s]            
             # variable = Voeis::Variable.first_or_create(
             #             :variable_code => @var.variable_code,
             #             :variable_name => @var.variable_name,
             #             :speciation =>  @var.speciation,
             #             :variable_units_id => @var.variable_units_id,
             #             :sample_medium =>  @var.sample_medium,
             #             :value_type => @var.value_type,
             #             :is_regular => @var.is_regular,
             #             :time_support => @var.time_support,
             #             :time_units_id => @var.time_units_id,
             #             :data_type => @var.data_type,
             #             :general_category => @var.general_category,
             #             :no_data_value => @var.no_data_value)
                        
             if Voeis::Variable.get(@var.id).nil?
                variable = Voeis::Variable.new
                variable.attributes = @var.attributes
                variable.save!
              else
               variable = Voeis::Variable.get(@var.id)
              end
             @col_vars[i] = variable
           end #end if
         end#managed repo
      end  #end i loop

      #create csv_row array
      @csv_row = Array.new
      csv_data = CSV.read(params[:datafile])
      i = params[:start_line].to_i-1
      d_time = DateTime.parse("#{params[:time]["stamp(1i)"]}-#{params[:time]["stamp(2i)"]}-#{params[:time]["stamp(3i)"]}T#{params[:time]["stamp(4i)"]}:#{params[:time]["stamp(5i)"]}:00#{ActiveSupport::TimeZone[params[:time][:zone]].utc_offset/(60*60)}:00")
      csv_data[params[:start_line].to_i-1..-1].each do |row|
        @csv_row[i] = row
            i = i + 1
            @row_num = i
          end#end row loop
          (params[:start_line].to_i-1..params[:csv_size].to_i).each do |row|
            if !@csv_row[row].nil?
            parent.managed_repository do
              #create sample
              puts @csv_row[row][@sample_col]
              @sample = Voeis::Sample.new(:sample_type =>   params["sample_type"+@row_num.to_s],
                                          :material => params["material"+@row_num.to_s],
                                          :lab_sample_code => @csv_row[row][@sample_col],
                                          :lab_method_id => params["lab_method_id"+@row_num.to_s].to_i,
                                          :local_date_time => @timestamp_col == -1 ? d_time : @csv_row[row][@timestamp_col].to_time)
              @sample.valid?
              puts @sample.errors.inspect()
              @sample.save
              @sample.sites << site
              @sample.save
              (0..range).each do |i|
                if @sample_col != i && @timestamp_col != i && @csv_row[row][i] != ""&& !params["ignore"+i.to_s]
                    new_data_val = Voeis::DataValue.new(:data_value => /^[-]?[\d]+(\.?\d*)(e?|E?)(\-?|\+?)\d*$|^[-]?(\.\d+)(e?|E?)(\-?|\+?)\d*$/.match(@csv_row[row][i].to_s) ? @csv_row[row][i].to_f : -9999.0, 
                       :local_date_time => @sample.local_date_time,
                       :utc_offset => @sample.local_date_time.to_time.utc_offset/(60*60),  
                       :date_time_utc => @sample.local_date_time.to_time.utc.to_datetime,  
                       :replicate => 0,
                       :string_value =>  @csv_row[row][i].blank? ? "Empty" : @csv_row[row][i]) 
                  new_data_val.valid?
                  puts new_data_val.errors.inspect() 
                  new_data_val.save
                  new_data_val.variable << @col_vars[i]
                  new_data_val.save
                  new_data_val.sample << @sample
                  new_data_val.save
                  @sample.variables << @col_vars[i]
                  @sample.save
                  samp_site = @sample.sites.first
                  samp_site.variables << @col_vars[i]
                  samp_site.save
                  # @sample.sites.each do |samp_site|
                  #                    samp_site.variables << @col_vars[i]
                  #                    samp_site.save
                  #                  end
                 end #end if
                end #end i loop
               end #end if @csv_array.nil?
            end #end managed repo
          end #end row loop
          parent.publish_his
          flash[:notice] = "File parsed and stored successfully."
          redirect_to project_path(params[:project_id])
    end# end def
   
   # Parses a csv file containing samples and data values
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
   def store_samples_and_data
     
     data_stream =""
     site = parent.managed_repository{Voeis::Site.first(:id => params[:site])}
     redirect_path =Hash.new
     if params[:no_save] != "no"
       #create a parsing template
       #create and save new DataStream
       parent.managed_repository do
         data_stream = Voeis::DataStream.create(:name => params[:template_name],
           :description => "NA",
           :filename => params[:datafile],
           :start_line => params[:start_line].to_i,
           :type => "Sample")
         #Add site association to data_stream
         #
         data_stream.sites << site
         data_stream.save
       end
       @timestamp_col = -1
       range = params[:row_size].to_i
       (0..range).each do |i|
         #create the Timestamp column
         if i == params[:timestamp_col].to_i && params[:timestamp_col] != "None"
           #puts params["column"+i.to_s]
           @timestamp_col = params[:timestamp_col].to_i
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
         elsif i == params[:sample_id].to_i
           @sample_col = params[:sample_id].to_i
            parent.managed_repository do
              data_stream_column = Voeis::DataStreamColumn.create(
                                    :column_number => i,
                                    :name => "SampleID",
                                    :type =>"SampleID",
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
                                   :type =>         "NA")
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
             else
               data_stream_column.name = "ignore"
               data_stream_column.data_streams << data_stream
               data_stream_column.save
             end #end if
           end #end managed repository
         end #end if
       end #end range.each
       @sample_col = params[:sample_id].to_i
     else #use the existing template
       data_stream = parent.managed_repository{Voeis::DataStream.first(:name => params[:template_name])}
       if !data_stream.data_stream_columns.first(:name => "Timestamp").nil?
         @timestamp_col = data_stream.data_stream_columns.first(:name => "Timestamp").column_number
       else
         @timestamp_col = -1
       end
       @sample_col = data_stream.data_stream_columns.first(:name => "SampleID").column_number
     end #end if 'no_save'
     range = params[:row_size].to_i
     #store all the Variables in the managed repository
     @col_vars = Array.new
     (0..range).each do |i|
        @var = Voeis::Variable.get(params["column"+i.to_s])
        parent.managed_repository do
          if !params["ignore"+i.to_s]            
            # variable = Voeis::Variable.first_or_create(
            #             :variable_code => @var.variable_code,
            #             :variable_name => @var.variable_name,
            #             :speciation =>  @var.speciation,
            #             :variable_units_id => @var.variable_units_id,
            #             :sample_medium =>  @var.sample_medium,
            #             :value_type => @var.value_type,
            #             :is_regular => @var.is_regular,
            #             :time_support => @var.time_support,
            #             :time_units_id => @var.time_units_id,
            #             :data_type => @var.data_type,
            #             :general_category => @var.general_category,
            #             :no_data_value => @var.no_data_value)
            if Voeis::Variable.get(@var.id).nil?
               variable = Voeis::Variable.new
               variable.attributes = @var.attributes
               variable.save!
             else
              variable = Voeis::Variable.get(@var.id)
             end
            @col_vars[i] = variable
          end #end if
        end#managed repo
     end  #end i loop
 
     #create csv_row array
     @csv_row = Array.new
     csv_data = CSV.read(params[:datafile])
     i = params[:start_line].to_i-1
     
     
     d_time = DateTime.parse("#{params[:time]["stamp(1i)"]}-#{params[:time]["stamp(2i)"]}-#{params[:time]["stamp(3i)"]}T#{params[:time]["stamp(4i)"]}:#{params[:time]["stamp(5i)"]}:00#{ActiveSupport::TimeZone[params[:time][:zone]].utc_offset/(60*60)}:00")
     csv_data[params[:start_line].to_i-1..-1].each do |row|
       @csv_row[i] = row
           i = i + 1
         end#end row loop
         (params[:start_line].to_i-1..params[:csv_size].to_i).each do |row|
           if !@csv_row[row].nil?
           parent.managed_repository do
             #create sample
             puts @csv_row[row][@sample_col]
             @sample = Voeis::Sample.new(:sample_type =>   params[:sample_type],
                                         :material => params[:material],
                                         :lab_sample_code => @csv_row[row][@sample_col],
                                         :lab_method_id => params[:lab_method_id].to_i,
                                         :local_date_time => @timestamp_col == -1 ? d_time : @csv_row[row][@timestamp_col].to_time)
             @sample.valid?
             puts @sample.errors.inspect()
             @sample.save
             @sample.sites << site
             @sample.save
             (0..range).each do |i|
               if @sample_col != i && @timestamp_col != i && @csv_row[row][i] != ""&& !params["ignore"+i.to_s]
                   new_data_val = Voeis::DataValue.new(:data_value => /^[-]?[\d]+(\.?\d*)(e?|E?)(\-?|\+?)\d*$|^[-]?(\.\d+)(e?|E?)(\-?|\+?)\d*$/.match(@csv_row[row][i].to_s) ? @csv_row[row][i].to_f : -9999.0, 
                      :local_date_time => @sample.local_date_time,
                      :utc_offset => @sample.local_date_time.to_time.utc_offset/(60*60),  
                      :date_time_utc => @sample.local_date_time.to_time.utc.to_datetime,  
                      :replicate => 0,
                      :string_value =>  @csv_row[row][i].blank? ? "Empty" : @csv_row[row][i]) 
                 new_data_val.valid?
                 puts new_data_val.errors.inspect() 
                 new_data_val.save
                 new_data_val.variable << @col_vars[i]
                 new_data_val.save
                 new_data_val.sample << @sample
                 new_data_val.save
                 @sample.variables << @col_vars[i]
                 @sample.save
                 samp_site = @sample.sites.first
                 samp_site.variables << @col_vars[i]
                 samp_site.save
                 # @sample.sites.each do |samp_site|
                 #                    samp_site.variables << @col_vars[i]
                 #                    samp_site.save
                 #                  end
                end #end if
               end #end i loop
              end #end if @csv_array.nil?
           end #end managed repo
         end #end row loop
         parent.publish_his
         flash[:notice] = "File parsed and stored successfully."
         redirect_to project_path(params[:project_id])
   end# end def
   
   # Parses a csv file containing sample data values
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
   def store_sample_data

     range = params[:row_size].to_i
     #store all the Variables in the managed repository
     @col_vars = Array.new
     (0..range).each do |i|
        @var = Voeis::Variable.get(params["column"+i.to_s])
        parent.managed_repository do
          if !params["ignore"+i.to_s]            
            # variable = Voeis::Variable.first_or_create(
            #             :variable_code => @var.variable_code,
            #             :variable_name => @var.variable_name,
            #             :speciation =>  @var.speciation,
            #             :variable_units_id => @var.variable_units_id,
            #             :sample_medium =>  @var.sample_medium,
            #             :value_type => @var.value_type,
            #             :is_regular => @var.is_regular,
            #             :time_support => @var.time_support,
            #             :time_units_id => @var.time_units_id,
            #             :data_type => @var.data_type,
            #             :general_category => @var.general_category,
            #             :no_data_value => @var.no_data_value)
            if Voeis::Variable.get(@var.id).nil?
               variable = Voeis::Variable.new
               variable.attributes = @var.attributes
               variable.save!
             else
              variable = Voeis::Variable.get(@var.id)
             end
            @col_vars[i] = variable
          end #end if
        end#managed repo
     end  #end i loop
 
     #create csv_row array
     @csv_row = Array.new
     csv_data = CSV.read(params[:datafile])
     i = params[:start_line].to_i-1

     csv_data[params[:start_line].to_i-1..-1].each do |row|
       @csv_row[i] = row
       i = i + 1
     end#end row loop
     (params[:start_line].to_i-1..params[:csv_size].to_i).each do |row|
       if !@csv_row[row].nil?
       parent.managed_repository do
         @sample = Voeis::Sample.get(params["csv_sample-"+(row+1).to_s])
         (0..range).each do |i|
           if params[:replicate].to_i != i && params[:timestamp_col].to_i != i && @csv_row[row][i] != ""&& !params["ignore"+i.to_s]
             #store data value for this column(i) and row
             #sort out replicate
             if params[:replicate] == "None"
               rep = "0"
             else
               rep = @csv_row[row][params[:replicate].to_i]
             end
             #need to store either the timestamp col or the applied timestamp
             #if params[:timestamp_col] == "None"
               #store the applied timestamp
               #d_time = DateTime.parse("#{params[:time]["stamp(1i)"]}-#{params[:time]["stamp(2i)"]}-#{params[:time]["stamp(3i)"]}T#{params[:time]["stamp(4i)"]}:#{params[:time]["stamp(5i)"]}:00#{ActiveSupport::TimeZone[params[:time][:zone]].utc_offset/(60*60)}:00")
               
               new_data_val = Voeis::DataValue.new(:data_value => /^[-]?[\d]+(\.?\d*)(e?|E?)(\-?|\+?)\d*$|^[-]?(\.\d+)(e?|E?)(\-?|\+?)\d*$/.match(@csv_row[row][i].to_s) ? @csv_row[row][i].to_f : -9999.0, 
                  :local_date_time => @sample.local_date_time,
                  :utc_offset => @sample.local_date_time.to_time.utc_offset/(60*60),  
                  :date_time_utc => @sample.local_date_time.to_time.utc.to_datetime,  
                  :replicate => rep,
                  :string_value =>  @csv_row[row][i].blank? ? "Empty" : @csv_row[row][i]) 
               new_data_val.valid?
               puts new_data_val.errors.inspect() 
               new_data_val.save

             new_data_val.variable << @col_vars[i]
             new_data_val.save
             new_data_val.sample << @sample
             new_data_val.save
             @sample.variables << @col_vars[i]
             @sample.save
             @sample.sites.each do |site|
               site.variables << @col_vars[i]
               site.save
             end
            end #end if
           end #end i loop
          end #end if @csv_array.nil?
       end #end managed repo
     end #end row loop
     #parent.publish_his
     flash[:notice] = "File parsed and stored successfully."
     redirect_to project_path(params[:project_id])
   end# end def

  def pre_process_samples
    @columns = [1,2,3,4,5,6]
  end
  

  # Gather information necessary to store samples and data
  #
  #
  #
  # @author Sean Cleveland
  #
  # @api public
  def pre_process_sample_file_upload
    @project = parent
    @templates = parent.managed_repository{Voeis::DataStream.all(:type => "Sample")}
  end
  
  
  # def pre_process_sample_file
  # 
  #   require 'csv_helper'
  #    
  #   @project = parent
  #    
  #   #save uploaded file if possible
  #   if !params[:datafile].nil? && datafile = params[:datafile]
  #     if ! ['text/csv', 'text/comma-separated-values', 'application/vnd.ms-excel',
  #           'application/octet-stream','application/csv'].include?(datafile.content_type)
  #       flash[:error] = "File type #{datafile.content_type} not allowed"
  #       redirect_to(:controller =>"voeis/data_values", :action => "pre_process_samples_file_upload", :params => {:id => params[:project_id]})
  # 
  #     else
  #       #file can be saved
  #       name = Time.now.to_s + params['datafile'].original_filename
  #       directory = "temp_data"
  #       @new_file = File.join(directory,name)
  #       File.open(@new_file, "wb"){ |f| f.write(params['datafile'].read)}
  #       
  #       @start_line = params[:start_line].to_i
  #       #get the first row that has information in the CSV file
  #       @start_row = get_row(@new_file, params[:start_line].to_i)
  #       @row_size = @start_row.size-1
  #       
  #       @header_rows = @start_line < 2 ? -1 : @start_line -2
  #   
  #       
  #       @columns = Array.new
  #       (1..@start_row.size).map{|x| @columns << x}
  #       @vars = Hash.new
  # 
  #       Voeis::Variable.all.each do |v| 
  # 
  #         @vars=@vars.merge({v.variable_name => v.id})
  #       end
  #       @sites = {"None"=>"None"}
  #       parent.managed_repository{Voeis::Site.all}.each do |s|
  #         @sites = @sites.merge({s.name => s.id})
  #       end
  # 
  #       @variables = Voeis::Variable.all
  #       @var_properties = Array.new
  #       Voeis::Variable.properties.each do |prop|
  #         @var_properties << prop.name
  #       end
  #       @var_properties.delete_if {|x| x.to_s == "id" || x.to_s == "his_id" || x.to_s == "time_units_id" || x.to_s == "is_regular" || x.to_s == "time_support" || x.to_s == "variable_code" || x.to_s == "created_at" || x.to_s == "updated_at"}
  #   
  #       debugger
  #       @variable = Voeis::Variable.new
  #       @units = Voeis::Unit.all
  #       @variable_names = Voeis::VariableNameCV.all
  #       @sample_mediums= Voeis::SampleMediumCV.all
  #       @sample_types = Voeis::SampleTypeCV.all
  #       @value_types= Voeis::ValueTypeCV.all
  #       @speciations = Voeis::SpeciationCV.all
  #       @data_types = Voeis::DataTypeCV.all
  #       @general_categories = Voeis::GeneralCategoryCV.all
  # 
  #       @label_array = Array["Variable Name","Variable Code","Unit Name","Speciation","Sample Medium","Value Type","Is Regular","Time Support","Time Unit ID","Data Type","General Cateogry"]
  #       @current_variables = Array.new     
  #       @variables.all(:order => [:variable_name.asc]).each do |var|
  #         @temp_array =Array[var.variable_name, var.variable_code,@units.get(var.variable_units_id).units_name, var.speciation,var.sample_medium, var.value_type, var.is_regular.to_s, var.time_support.to_s, var.time_units_id.to_s, var.data_type, var.general_category]
  #         @current_variables << @temp_array
  #       end
  #       
  #       @sample_type_options = Array.new
  #       @sample_types.all(:order => [:term.asc]).each do |samp_type|
  #         @sample_type_options <<[samp_type.term]  
  #       end
  # 
  #       @sample_medium_options = Array.new
  #       @sample_mediums.all(:order => [:term.asc]).each do |mat|
  #         @sample_medium_options << [mat.term]
  #       end
  #       #parse csv file into array
  #       @csv_array = Array.new
  #       csv_data = CSV.read(@new_file)
  #       i = 0
  #       csv_data[0..-1].each do |row|
  #         temp_array = Array.new
  #         row.map! { |k| temp_array << k }
  #         @csv_array[i] = temp_array
  #         i = i + 1
  #       end
  #       @csv_size = i -1
  #     end       
  # 
  #   else
  #       redirect_to(:controller =>"voeis/data_values", :action => "pre_process_sample_file_upload", :params => {:id => params[:project_id]})
  #     end
  #   
  # end
  
  
  # pre_process_samples_files
  # This is the Sample Wizard Upload Second Step for describing how to parse a CSV file
  # @author Sean Cleveland
  # @api public
  def pre_process_samples_file
    
       require 'csv_helper'
       @data_template = parent.managed_repository{Voeis::DataStream.get(params[:data_template_id].to_i)}  
       @project = parent
       @current_user = current_user
       #save uploaded file if possible
       if !params[:datafile].nil? && datafile = params[:datafile]
         if !params['datafile'].original_filename.include?(".csv") &&
                !params['datafile'].original_filename.include?(".xls") &&
                !params['datafile'].original_filename.include?(".xlsx") &&
                !params['datafile'].original_filename.include?(".dat")
           flash[:error] = "File #{params['datafile'].original_filename} has an usupported file extension.  Voeis accepts .csv, .xls, .xlsx and .dat(csv format)."
           redirect_to(:controller =>"voeis/data_values", :action => "pre_process_samples_file_upload", :params => {:id => params[:project_id]})
    
         else
          begin
             #file can be saved
             name = Time.now.to_s + params['datafile'].original_filename
             directory = "temp_data"
             @new_file = File.join(directory,name)
             File.open(@new_file, "wb"){ |f| f.write(params['datafile'].read)}
             if name.include?('.xlsx')
               xlsx = Excelx.new("#{directory}/#{name}")
               csv_name = name.gsub('.xlsx','csv')
               xlsx.to_csv("#{directory}/#{csv_name}")
               @new_file = File.join(directory,csv_name)
             elsif name.include?('.xls')
               xls = Excel.new("#{directory}/#{name}")
               csv_name = name.gsub('.xls', '.csv')
               xls.to_csv("#{directory}/#{csv_name}")
               @new_file = File.join(directory,csv_name)
             end
             @start_line = params[:start_line].to_i
             #get the first row that has information in the CSV file
             @start_row = get_row(@new_file, params[:start_line].to_i)
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
             if @site.time_zone_offset.to_s == "unknown"
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
       
    
             @variable = Voeis::Variable.new
             @labs = Voeis::Lab.all
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
             @value_types= Voeis::ValueTypeCV.all
             @speciations = Voeis::SpeciationCV.all
             @data_types = Voeis::DataTypeCV.all
             @general_categories = Voeis::GeneralCategoryCV.all
             @batch = Voeis::MetaTag.first_or_create(:name => "Batch", :category =>"Chemistry")
    
             @label_array = Array["Variable Name", "Variable Code", "Unit Name", 
                                  "Speciation", "Sample Medium", "Value Type",
                                  "Is Regular", "Time Support", "Time Unit ID", 
                                  "Data Type", "General Cateogry"]
             @current_variables = Array.new 
             @variables.all(:order => [:variable_name.asc]).each do |var|
               @temp_array =Array[var.variable_name, var.variable_code,@units.get(var.variable_units_id).units_name, var.speciation,var.sample_medium, var.value_type, var.is_regular.to_s, var.time_support.to_s, var.time_units_id.to_s, var.data_type, var.general_category]
               @current_variables << @temp_array
             end
           
             @sample_type_options = Array.new
             @sample_types.all(:order => [:term.asc]).each do |samp_type|
               @sample_type_options <<[samp_type.term]  
             end
    
             @sample_medium_options = Array.new
             @sample_mediums.all(:order => [:term.asc]).each do |mat|
               @sample_medium_options << [mat.term]
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
        rescue
          flash[:error] = "File #{params['datafile'].original_filename} could not be parsed correclty by VOEIS.  Check your file to be sure it is correct."
          redirect_to(:controller =>"voeis/data_values", :action => "pre_process_samples_file_upload", :params => {:id => params[:project_id]})
        end
      end       
    else
      redirect_to(:controller =>"voeis/data_values", :action => "pre_process_samples_file_upload", :params => {:id => params[:project_id]})
    end 
  end
 
  # Parses a csv file containing samples and data values
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
   def store_samples_and_data_from_file
     require 'chronic'  #for robust timestamp parsing
     begin #rescue errors
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
     end
     
     columns_array = Array.new
     ignore_array = Array.new
     meta_tag_array = Array.new
     (1..params[:row_size].to_i).each do |i|
       columns_array[i-1]  = params["column"+i.to_s]
       ignore_array[i-1] = params["ignore"+i.to_s]
       meta_tag_array[i-1] = params["tag_column"+i.to_s]
       if params["column"+i.to_s] == "timestamp"
         timestamp_col = i-1
       elsif params["column"+i.to_s] == "sample_id"
         sample_id_col = i-1
       elsif params["column"+i.to_s] == "vertical_offset"
          vertical_offset_col = i-1
       elsif params["column"+i.to_s] == "starting_vertical_offset"
           vertical_offset_col = i-1
       elsif params["column"+i.to_s] == "ending_vertical_offset"
            ending_vertical_offset_col = i-1
       end
     end
     if !params[:DST].nil?
       dst_time = 1
       dst = true
     else
      dst_time = 0
      dst = false
     end
     #if the timestamp is in UTC then don't apply the calculate utc_offset just use 0
     if params[:time_support] == "UTC"
       dstream_utc_offset = 0
     else
       dstream_utc_offset = params[:utc_offset].to_i
     end
     #get or create the DataStream
     if params[:save_template] == "true"
       data_stream_id = create_sample_and_data_parsing_template(params[:template_name], timestamp_col, sample_id_col, columns_array, ignore_array, site, params[:datafile], params[:start_line], params[:row_size], vertical_offset_col, ending_vertical_offset_col, meta_tag_array, dstream_utc_offset, dst, @project_source)
       data_stream = parent.managed_repository{Voeis::DataStream.get(data_stream_id[:data_template_id])}
     else
       data_stream = parent.managed_repository{Voeis::DataStream.get(params[:data_stream_id])}
     end 
      
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
           #            :no_data_value => @var.no_data_value,
           #            :detection_limit => @var.detection_limit,
           #            :value_type => @var.value_type,
           #            :field_method_id => @var.field_method_id,
           #            :lab_id => @var.lab_id,
           #            :lab_method_id => @var.lab_method_id,
           #            :spatial_offset_type => @var.spatial_offset_type,
           #            :spatial_offset_value => @var.spatial_offset_value,
           #            :spatial_units_id => @var.spatial_units_id
           #            )
            if Voeis::Variable.get(@var.id).nil?
               variable = Voeis::Variable.new
               variable.attributes = @var.attributes
               variable.save!
             else
              variable = Voeis::Variable.get(@var.id)
             end
            @col_vars[i] = variable
            @variables << variable
            site.variables << variable
            site.save
          end#managed repo
        end #end if
     end  #end i loop
     #site.save
     #create csv_row array
     #@csv_row = Array.new
     #csv_temp_data = CSV.read(params[:datafile])
     #csv_size = csv_temp_data.length
     #csv_data = CSV.read(params[:datafile])
     
     #i = params[:start_line].to_i
     @results =""
     parent.managed_repository do 
       @results = Voeis::DataValue.parse_logger_csv(params[:datafile], data_stream.id, site.id, params[:start_line].to_i, params[:sample_type], params[:sample_medium],current_user.id)
     
     # csv_data[params[:start_line].to_i-1..-1].each do |row|
     #   @csv_row[i] = row
     #       i = i + 1
     # end#end row loop
         # (params[:start_line].to_i-1..csv_size.to_i).each do |row|
         #   if !@csv_row[row].nil?
         #   #create meta_tag_data
         #    row_meta_tag_array = Array.new #store the current rows MetaTagData objects for association later
         #    data_stream.data_stream_columns.all(:name=>"MetaTag").each do |col| 
         #      @mtag = col.meta_tag
         #      parent.managed_repository do
         #        mdtag = Voeis::MetaTag.new(:name=>@mtag.name, :category=>@mtag.category)
         #        mdtag.value = @csv_row[row][col.column_number]
         #        
         #        mdtag.save
         #        row_meta_tag_array << mdtag
         #      end #managed_repository
         #    end #data_stream_columns
         #   parent.managed_repository do
         #     #create sample
         #     @site = Voeis::Site.get(site.id)
         #     #calculate the correct local_offset
         #     sample_datetime = Chronic.parse(@csv_row[row][timestamp_col]).to_datetime
         #     sampletime = DateTime.civil(sample_datetime.year,sample_datetime.month,
         #                  sample_datetime.day,sample_datetime.hour,sample_datetime.min,
         #                  sample_datetime.sec, (data_stream.utc_offset+dst_time)/24.to_f)
         #     
         #     @sample = Voeis::Sample.new(:sample_type =>   params[:sample_type],
         #                                 :material => params[:sample_medium],
         #                                 :lab_sample_code => @csv_row[row][@sample_col],
         #                                 :lab_method_id => -1,
         #                                 :local_date_time => sampletime)           
         #     @sample.save
         #     @site.samples << @sample
         #     @site.save
         #     @col_vars.each do |var| 
         #       if !var.nil?
         #         var.samples << @sample
         #         var.save
         #       end
         #     end
         #     
         #     (0..range).each do |i|
         #       puts i
         #       if columns_array[i] != "ignore" && sample_id_col != i && timestamp_col != i &&
         #          columns_array[i] != nil && vertical_offset_col != i && 
         #          ending_vertical_offset_col != i && meta_tag_array[i].to_i == -1
         # 
         #           new_data_val = Voeis::DataValue.new(:data_value => /^[-]?[\d]+(\.?\d*)(e?|E?)(\-?|\+?)\d*$|^[-]?(\.\d+)(e?|E?)(\-?|\+?)\d*$/.match(@csv_row[row][i].to_s) ? @csv_row[row][i].to_f : -9999.0, 
         #              :local_date_time => sampletime,
         #              :utc_offset => data_stream.utc_offset+dst_time,
         #              :observes_daylight_savings => dst,
         #              :date_time_utc => sampletime.utc,  
         #              :replicate => 0,
         #              :quality_control_level=>@col_vars[i].quality_control.to_i,
         #              :string_value =>  @csv_row[row][i].blank? ? "Empty" : @csv_row[row][i],
         #              :vertical_offset =>  vertical_offset_col == "" ? 0.0 : @csv_row[row][vertical_offset_col].to_i,
         #              :end_vertical_offset => ending_vertical_offset_col == "" ? nil : @csv_row[row][ending_vertical_offset_col].to_i) 
         #         new_data_val.save
         #         @site.data_values << new_data_val
         #         @site.save
         #         new_data_val.variable << @col_vars[i]
         #         new_data_val.source = @project_source
         #         new_data_val.sample << @sample
         #         row_meta_tag_array.map{|mtag| new_data_val.meta_tags << mtag}  #add meta_data
         #         new_data_val.save
         #         new_data_val.data_streams << data_stream
         #         new_data_val.save
         #         @sample.data_streams << data_stream
         #         @sample.save
         #        end #end if
         #       end #end i loop
         #      end #end if @csv_array.nil?
         #   end #end managed repo
         # end #end row loop
           puts "updating the site catalog" 
           Voeis::Site.get(site.id).update_site_data_catalog_variables(@variables)
         end #end repo
         #parent.publish_his
         flash[:notice] = "File parsed and stored successfully for #{site.name}. #{@results[:total_records_saved]} data values saved and #{@results[:total_rows_parsed]} rows where parsed. "
         redirect_to project_path(params[:project_id]) and return
         rescue Exception => e  
           email_exception(e,request.env)
           parent.managed_repository{Voeis::Site.get(site.id).update_site_data_catalog}
           flash[:error] = "Problem Parsing Sample File: "+ e.message
           redirect_to(:controller =>"voeis/data_values", :action => "pre_process_samples_file_upload", :params => {:id => params[:project_id]})
         end
   end# end def

    
    
    
   
   
   #columns is an array of the columns that store the variable id
   def create_sample_and_data_parsing_template(template_name, timestamp_col, sample_id_col, columns_array, ignore_array, site, datafile, start_line, row_size, vertical_offset_col, ending_vertical_offset_col, meta_tag_array, utc_offset, dst,source)
      parent.managed_repository do
        @data_stream = Voeis::DataStream.create(:name => template_name.to_s,
          :description => "NA",
          :filename => datafile,
          :start_line => start_line.to_i,
          :type => "Sample",
          :source => source,
          :utc_offset => utc_offset,
          :DST => dst)
        #Add site association to data_stream

        @data_stream.sites << site
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
        elsif  columns_array[i] != nil  || columns_array[i] != ""#create other data_stream_columns and create variables
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
            #             :no_data_value => var.no_data_value,
            #             :detection_limit => var.detection_limit,
            #             :value_type => var.value_type,
            #             :field_method_id => var.field_method_id,
            #             :lab_id => var.lab_id,
            #             :lab_method_id => var.lab_method_id,
            #             :spatial_offset_type => var.spatial_offset_type,
            #             :spatial_offset_value => var.spatial_offset_value,
            #             :spatial_units_id => var.spatial_units_id
            #             )
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
          end #end managed repository
        end #end if
      end #end range.each
      data_template_hash = Hash.new
      #return our Awesome new data_stream or template if you would be so kind
      data_template_hash = {:data_template_id => @data_stream.id}
   end
 
end
