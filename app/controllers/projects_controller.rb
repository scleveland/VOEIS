require 'responders/rql'

class ProjectsController < InheritedResources::Base
  responders :rql
  respond_to :html, :json
  layout :choose_layout

  has_widgets do |root|
    root << widget(:vertical_datum)
    root << widget(:site_pane2)
  end
  
  def choose_layout
    if action_name == 'index'
      return 'split_map'
    else
      return 'application'
    end
  end
  def update
    @project = Project.get(params[:id])
     @project.is_private = params[:project][:is_private].to_i
     @project.description = params[:project][:description]
     @project.publish_to_his = params[:project][:publish_to_his].to_i
     respond_to do |format|
       if @project.save
         flash[:notice] = 'Project was successfully updated.'
         format.json do
           render :json => @project.as_json, :callback => params[:jsoncallback]
         end
         format.html {render :action => "edit"}
       else
         flash[:error] = 'Project was NOT updated.'
         format.html { render :action => "edit" }
       end
     end
  end
  def index
    ### PUBLIC & USER PROJECTS ###
    @projects = Project.all(:is_private=>false)
    if !current_user.nil?
      user_projects = current_user.projects.all(:is_private=>true)
      #current_user.projects.all(:is_private=>true, :fields=>[:id, :name, :description]).map {|project| @user_projects << {"id" => project.id.to_s, "name" => project.name, "description" => project.description} }
      @projects += user_projects
    end
    index! do
      logger.debug(request.env['QUERY_STRING'])
    end
  end
  
  #export the results of search/browse to a csv file
  def export
    headers = JSON[params[:column_array]]
    rows = JSON[params[:row_array]]
    column_names = Array.new
    headers.each do |col|
      column_names << col
    end
    csv_string = CSV.generate do |csv|
      csv << column_names
      rows.each do |row|
        csv << row
      end
    end

    filename = params[:file_name] + ".csv"
    send_data(csv_string,
    :type => 'text/csv; charset=utf-8; header=present',
    :filename => filename)
  end

  def show
    # This should be a [
    #                   [ timestamp, site.sensor.variable.value, site.sensor.variable.value ]
    #                   [ timestamp, site.sensor.variable.value, site.sensor.variable.value ]
    #                   [ ... ]
    #                  ]
    if resource.nil?
      flash[:error] = "Could not find that project"
      redirect_to(projects_path()) and return
    end
    @site = @project.managed_repository{ Voeis::Site.new }
    @sites = @project.managed_repository{ Voeis::Site.all }
    @site1 = @sites[0]
    @site_stats = []
    @site_var_stats = []
    @site_ref = []
    @site_samps = []
    @variable_labels = Array["Variable Data","Count","Start","End"]
    @sample_labels = Array["Sample Type","Lab Sample Code","Sample Medium","Timestamp"]
    @sample_fields = Array["sample_type","lab_sample_code","material","local_date_time"]
    @site_ref_props = []
    @site_properties = @site.properties.map{ |prop| 
      #prop = prop.name.to_s
      if prop.name.to_s[-3..-1]=='_id'
        prop.name.to_s[0..-4]
        #@site_ref_props << prop
      else
        prop.name.to_s
      end
    }
    
    @sites.each{ |site| 
      vert_datum = site.vertical_datum.nil? ? '' : site.vertical_datum.term.to_s
      local_proj = site.local_projection.nil? ? '' : site.local_projection.term.to_s
      @site_ref << {:vert_datum=>vert_datum, :local_proj=>local_proj}
    }
    
    @sites.each{ |site| 
      stats = @project.managed_repository{Voeis::SiteDataCatalog.all(:site_id=>site.id)}.aggregate(:record_number.sum, :starting_timestamp.min, :ending_timestamp.max)
      stats.map!{ |x| 
        if x.nil?
          x = 'NA'
        else
          if x.class.to_s[0,4]=='Date'
            x = x.strftime('%m/%d/%Y')
          else
            x = x
          end
        end
      }
      @site_stats << {:vars=>site.variables.count, :count=>stats[0], :first=>stats[1], :last=>stats[2]}
    }
    
    #@site_var_stats = @project.managed_repository{Voeis::SiteDataCatalog.all(:order=>site.id)}
    @sites.each{ |site| 
      @temp_array = []
      site.variables.map{ |var|
        stats = @project.managed_repository{Voeis::SiteDataCatalog.first(:site_id=>site.id, :variable_id=>var.id)}
        if !stats.nil?
          var_stats = [stats.record_number, stats.starting_timestamp, stats.ending_timestamp]
          var_stats.map!{ |x| 
            if x.nil?
              x = 'NA'
            else
              if x.class.to_s[0,4]=='Date'
                x = x.strftime('%m/%d/%Y')
              else
                x = x
              end
            end
          }
        else
          var_stats = ['NA', 'NA', 'NA']
        end
        @temp_array << {:varname=>var.variable_name, :varid=>var.id, :count=>var_stats[0], :first=>var_stats[1], :last=>var_stats[2]}
      }
      @site_var_stats << @temp_array
    }
    
    @sites.each{ |site| 
      @temp_array = []
      site.samples.all(:order => [:lab_sample_code.asc]).each { |samp|
        @temp_array << Array[samp.sample_type, samp.lab_sample_code, samp.material, samp.local_date_time.to_s]
      }
      @site_samps << @temp_array
    }
    
    @current_data = Array.new
    @items = Array.new
    @start_time = nil
    @end_time = nil
    @label_array = ["Timestamp"]
    if params.has_key?(:range)
      @start_time = Date.civil(params[:range][:"start_date(1i)"].to_i,params[:range]      [:"start_date(2i)"].to_i,params[:range][:"start_date(3i)"].to_i)
      @end_time = Date.civil(params[:range][:"end_date(1i)"].to_i,params[:range]    [:"end_date(2i)"].to_i,params[:range][:"end_date(3i)"].to_i)
      @start_time = @start_time.to_datetime
      @end_time = @end_time.to_datetime + 23.hour + 59.minute


      # Create the Labels for the header
      var_label=""
      if params.has_key?(:variables)
        params[:variables].keys.each do |site_id|
          site = resource.managed_repository { Voeis::Site.get(site_id) }
          if params[:variables][site_id].empty?
            site.variables.each do |variable|
              var_label = ""
              var_label =  site.name if params[:site_display]
              var_label = var_label +  variable.variable_name
              var_label = var_label + variable.sample_medium if params[:sample_medium_display]
              var_label = var_label + variable.data_type if params[:data_type_display]
              var_label = var_label + Voeis::Unit.get(variable.variable_units_id).units_name if params[:units_display]

              @label_array << var_label #"#{site.name} #{variable.variable_name}"
              @items << [site, variable]
            end
          else
            params[:variables][site_id].each do |variable_id|
              variable = resource.managed_repository{ Voeis::Variable.get(variable_id) }
              var_label = ""
              var_label =  site.name + "|" if params[:site_display]
              var_label = var_label +  variable.variable_name
              var_label = var_label + "|" + variable.sample_medium if params[:sample_medium_display]
              var_label = var_label + "|" + variable.data_type if params[:data_type_display]
              var_label = var_label + "|" + Voeis::Unit.get(variable.variable_units_id).units_name if params[:units_display]
              @label_array << var_label #{}"#{site.name} #{variable.variable_name}"
              @items << [site, variable]
            end
          end
        end
      end

      # Fill in the current data
      data_lists = Hash.new
      timestamps = Set.new
      @items.each do |site, variable|
        #get sensor data
        if site.sensor_types.count > 0
          sensor = site.sensor_types.select{|s| s.variables.include?(variable)}[0]
          if !sensor.nil?
            values = sensor.sensor_values.all(:timestamp.gte => @start_time, :timestamp.lte => @end_time)
            data_lists[site] ||= Hash.new
            data_lists[site][variable] ||= Hash.new
            values.each do |v|
              data_lists[site][variable][v.timestamp] = v.value
            end
            timestamps.merge(values.map {|v| v.timestamp})
          end
        end
        #get sample data
        if site.samples.count > 0
          sample = site.samples.select{|s| s.variables.include?(variable)}[0]
          if !sample.nil?
            values = sample.data_values.all(:local_date_time.gte => @start_time, :local_date_time.lte => @end_time).intersection(variable.data_values)
            data_lists[site] ||= Hash.new
            data_lists[site][variable] ||= Hash.new
            values.each do |v|

                data_lists[site][variable][v.local_date_time] = v.data_value

            end
            timestamps.merge(values.map {|v| v.local_date_time})
          end
        end
      end

      timestamps.to_a.sort.each do |ts|
        tmp_array = Array.new
        tmp_array << ts
        @items.each do |site, variable|
          if data_lists[site][variable].has_key?(ts)
            value = data_lists[site][variable][ts]
          else
            value = nil
          end
          tmp_array << value
        end
        @current_data << tmp_array
      end
    end
    super
  end

  def destroy
    flash[:notice] = "Project deleting is disabled."
    redirect_to(:back)
  end
  
  def get_user_projects
    @projects = Array.new
    current_user.projects.all(:fields => [:id, :name, :description]).map {|project| @projects << {"id" => project.id.to_s, "name" => project.name, "description" => project.description} }
    respond_to do |format|
      format.json do
       render :json => @projects.as_json, :callback => params[:jsoncallback]
      end
      format.xml do
       render :xml => @projects.to_xml
      end
    end
  end

  protected
  def resource
    @project ||= resource_class.get(params[:id])
  end

  def collection
    @projects ||= resource_class.paginate(:page => params[:page], :per_page => 3)
  end

  def resource_class
    @initial_query ||= begin
      q = Project.all(:is_private => false)
      q =  (q | current_user.projects ) unless current_user.nil?
      q.access_as(current_user)
    end
  end








  def get_json_data(data_stream_ids, variable_ids, start_date = nil, end_date= nil, hour = nil)
    if !data_stream_ids.empty?
      @download_meta_array = Array.new
      data_stream_ids.each do |data_stream_id|
        data_stream = parent.managed_repository{Voeis::DataStream.get(data_stream_id)}
        site = data_stream.sites.first
        @sensor_hash = Hash.new
        data_stream.data_stream_columns.all(:order => [:column_number.asc]).each do |data_col|
          @value_array= Array.new
          sensor = data_col.sensor_types.first

          if !sensor.nil?
            if !sensor.variables.empty?
              if !variable_ids.nil?
                var = sensor.variables.first
                variable_ids.each do |var_id|
                  if var.id == var_id.to_i
                    if !start_date.nil? && !end_date.nil?
                      sensor.sensor_values(:timestamp.gte => start_date,:timestamp.lte => end_date, :order => (:timestamp.asc)).each do |val|
                        @value_array << [val.timestamp, val.value]
                      end #end do val
                    elsif !hours.nil?
                      last_date = sensor.sensor_values.last(:order => [:timestamp.asc]).timestamp
                      start_date1 = (last_date.to_time - params[:hours].to_i.hours).to_datetime
                      sensor.sensor_values(:timestamp.gte => start_date1, :order => (:timestamp.asc)).each do |val|
                        @value_array << [val.timestamp, val.value]
                      end #end do val
                    end #end if
                    @data_hash = Hash.new
                    @data_hash[:data] = @value_array
                    @sensor_meta_array = Array.new
                    variable = sensor.variables.first
                    @sensor_meta_array << [{:variable => variable.variable_name},
                      {:units => Voeis::Unit.get(variable.variable_units_id).units_abbreviation},
                      @data_hash]
                      @sensor_hash[sensor.name] = @sensor_meta_array
                    end #end if
                  end #end do var_id
                end # end if
              end # end if
            end #end if
          end #end do data col
          @download_meta_array << [{:site => site.name},
            {:site_code => site.code},
            {:lat => site.latitude},
            {:longitude => site.longitude},
            {:sensors => @sensor_hash}]
          end #end do data_stream
        end # end if
        # end
        @download_meta_array.to_json
        # respond_to do |format|
        #   format.json do
        #     format.html
        #     render :json => @download_meta_array, :callback => params[:jsoncallback]
        #   end
        # end
      end
    end
