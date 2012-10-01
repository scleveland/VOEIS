class Voeis::SearchController < Voeis::BaseController

  layout :choose_layout, :only=>[:index, :parallel_coordinate_d3]

  # Properly override defaults to ensure proper controller behavior
  # @see Voeis::BaseController

  def new
    @sites = parent.managed_repository{Voeis::Site.all}
    @variables = parent.managed_repository{Voeis::Variable.all}
    @units = Voeis::Unit.all
    @unit_names = Hash.new
    @units.map{|u| @unit_names = @unit_names.merge({u.id => u.units_name})}
    if parent.managed_repository{Voeis::SiteDataCatalog.count} > 0
      @start_date = parent.managed_repository{Voeis::SiteDataCatalog.first(:order=>[:starting_timestamp])}
      @end_date = parent.managed_repository{Voeis::SiteDataCatalog.last(:order=>[:ending_timestamp], :ending_timestamp.not => nil)}
    else
      @start_date= parent.managed_repository{Voeis::SiteDataCatalog.new(:starting_timestamp=>DateTime.now)}
      @end_date=parent.managed_repository{Voeis::SiteDataCatalog.new(:ending_timestamp=>DateTime.now)}
    end
    
    debugger
  end
  
  def index

       #@tabId = params[:tab_id]
        site_ids    = params[:site_ids].split(',')
        variable_ids = params[:var_ids].split(',')
        start_date   = params[:start_date]
        end_date     = params[:end_date]
        @start_date = Date.parse(start_date)
        @end_date = Date.parse(end_date)
        @units = Voeis::Unit.all
        @unit_names = Hash.new
        @units.map{|u| @unit_names = @unit_names.merge({u.id => u.units_abbreviation})}
        @sites = ""
        data = ""
        @variables = ""
        parent.managed_repository do
          data = DataMapper.raw_select(Voeis::DataValue.all(:variable_id => variable_ids, 
                                :site_id => site_ids,
                                :local_date_time.gte => start_date,
                                :local_date_time.lte => end_date,
                                :fields=>[:date_time_utc, :data_value,:variable_id, :site_id],
                                :order=>[:date_time_utc]))
          
          @sites = Voeis::Site.all(:id=>site_ids)
          @variables = Voeis::Variable.all(:id=> variable_ids)
        end
        site_names = {}
        @sites.map{|s| site_names[s.id]=s.code}
        variable_names = {}
        @variables.map{|v| variable_names[v.id]= v.variable_name+"("+@unit_names[v.variable_units_id]+")"}
        @dv_count = data.count
        #results = {}
        presults = {}
        @variable_ids=[]
        # result[timestamp] = {var_id=>val,var_id=>val,var_id=>val}
        data.each do |d|
          #results[d.date_time_utcto_datetime.change(:offset => "+00:00")] ||= {}
          #results[d.date_time_utc.to_datetime.change(:offset => "+00:00")][d.variable_id] = d.data_value
          # presults[(Time.at((d.date_time_utc.to_time.change(:offset => "+00:00").to_f / 60).round * 60)).to_datetime.change(:offset => "+00:00")] ||= {}
          # presults[(Time.at((d.date_time_utc.to_time.change(:offset => "+00:00").to_f / 60).round * 60)).to_datetime.change(:offset => "+00:00")]["#{site_names[d.site_id]}: #{variable_names[d.variable_id]}"] = d.data_value
          
          presults[d.date_time_utc.to_datetime.change(:offset => "+00:00")] ||= {}
          presults[d.date_time_utc.to_datetime.change(:offset => "+00:00")]["#{site_names[d.site_id]}: #{variable_names[d.variable_id]}"] = d.data_value
          
          #@variable_ids << d.variable_id unless @variable_ids.include?(d.variable_id)
          @variable_ids << "#{site_names[d.site_id]}: #{variable_names[d.variable_id]}" unless  @variable_ids.include?("#{site_names[d.site_id]}: #{variable_names[d.variable_id]}")
        end
        # null_variables={}
        # if !@variable_ids.empty?
        #   @variable_ids.each do |v|
        #     if !v.nil?
        #       null_variables["var_#{v}"] = -9999
        #     end
        #     @variables << parent.managed_repository{Voeis::Variable.get(v)}
        #   end
        # end
        @parallel_results=[]
        var_ids_hash = {:Timestamp => nil}
        @variable_ids.each{|v| var_ids_hash[v.to_sym]=nil}
        @parallel_results << var_ids_hash
        presults.each do |k,pr| 
          #@parallel_results << {:timestamp => k}.merge(null_variables.merge(pr))
          @parallel_results << {:Timestamp => k}.merge(pr)
        end
   respond_to do |format|
     format.html do
       render :index 

     end
     format.json do
       render :json => data.sql_to_json, :callback => params[:jsoncallback]
     end
     format.xml do
       render :xml => data.sql_to_xml
     end
     format.csv do
      unless @parallel_results.first.nil?
        csv_string = CSV.generate do |csv|
          csv << @parallel_results.first.keys
          @parallel_results.each do |pr|
            csv << pr.values
          end
        end
      else
        csv_string =""
      end
      filename ="voeis_data.csv"
      send_data(csv_string,
        :type => 'text/csv; charset=utf-8; header=present',
        :filename => filename)
     end
   end
  end
  
  
  def parallel_coordinates
     #@tabId = params[:tab_id]
     site_ids    = params[:site_ids].split(',')
     variable_ids = params[:var_ids].split(',')
     start_date   = params[:start_date]
     end_date     = params[:end_date]
     @start_date = Date.parse(start_date)
     @end_date = Date.parse(end_date)
     @units = Voeis::Unit.all
     @unit_names = Hash.new
     @units.map{|u| @unit_names = @unit_names.merge({u.id => u.units_abbreviation})}
     data = ""
     @variables = []
     parent.managed_repository do
       data = DataMapper.raw_select(Voeis::DataValue.all(:variable_id => variable_ids, 
                             :site_id => site_ids,
                             :local_date_time.gte => start_date,
                             :local_date_time.lte => end_date,
                             :fields=>[:date_time_utc, :data_value,:variable_id, :site_id]))
       #data =Voeis::DataValue.all(:variable_id => variable_ids, 
                             # :site_id => site_ids,
                             # :local_date_time.gte => start_date,
                             # :local_date_time.lte => end_date)
      # @variables  = data.variables(:unique=>true)

     end
    
     respond_to do |format|

     format.json do
       render :json => data.sql_to_json, :callback => params[:jsoncallback]
     end
     format.xml do
       render :xml => data.sql_to_xml
     end
     format.csv do
       render :text => data.sql_to_csv.to_s.gsub(/\n\n/, "\n")
     end
   end

  end
  
  def download_deq    
    site_ids    = params[:site_ids].split(',')
    variable_ids = params[:var_ids].split(',')
    start_date   = params[:start_date]
    end_date     = params[:end_date]
    @start_date = Date.parse(start_date)
    @end_date = Date.parse(end_date)
    @units = Voeis::Unit.all
    @unit_names = Hash.new
    @units.map{|u| @unit_names = @unit_names.merge({u.id => u.units_abbreviation})}
    @sites = ""
    data = ""
    @variables = ""
    parent.managed_repository do
      @sites = Voeis::Site.all(:id=>site_ids)
      @variables = Voeis::Variable.all(:id=> variable_ids)
      if params[:small_data] == true
        data = DataMapper.raw_select(Voeis::DataValue.all(:variable_id => variable_ids, 
                              :site_id => site_ids,
                              :local_date_time.gte => start_date,
                              :local_date_time.lte => end_date,
                              :fields=>[:date_time_utc, :data_value,:variable_id, :site_id],
                              :order=>[:date_time_utc]))
        data.each do |dv|
          dv.date_time_utc = adjust_utc_time_gmt(dv)
        end
      else
        data = DataMapper.raw_select(Voeis::DataValue.all(:variable_id => variable_ids, 
                              :site_id => site_ids,
                              :local_date_time.gte => start_date,
                              :local_date_time.lte => end_date,
                              :order=>[:date_time_utc]))
        data.each do |dv|
          dv.local_date_time = adjust_utc_time_local(dv)
          dv.date_time_utc = adjust_utc_time_gmt(dv)
        end
      end
    end
    respond_to do |format|
       format.json do
         render :json => data.sql_to_json, :callback => params[:jsoncallback]
       end
       format.xml do
         render :xml => data.sql_to_xml
       end
       format.csv do
         filename ="voeis_data.csv"
         send_data(data.sql_to_csv.to_s.gsub(/\n\n/, "\n"),
           :type => 'text/csv; charset=utf-8; header=present',
           :filename => filename)
       end
     end
  end
  
  #export the results of search/browse to a csv file
  def export
    filename ="voeis_data.csv"
    send_data(params[:export][:data],
      :type => 'text/csv; charset=utf-8; header=present',
      :filename => filename)
  end

  
  private
  
  def choose_layout
    if action_name == 'parallel_coordinates_d3' || action_name == 'index' 
      return 'pc_layout'
    else
      return 'application'
    end
  end
  
  def adjust_utc_time_local(val)
      tz0 = val['utc_offset'].to_s.split('.');
      tz = (tz0[0][0]=='-' ? '-' : '+')+('00'+tz0[0].to_i.abs.to_s)[-2,2]+':';
      tz += tz0.count>1 ? ('0'+((('.'+tz0[1]).to_f*100).to_i*0.6).to_i.to_s)[-2,2] : '00';
      return val['local_date_time'].to_datetime.change(:offset => tz).to_time
  end
  
  def adjust_utc_time_gmt(val)
      return val['date_time_utc'].to_datetime.change(:offset => "+00:00")
  end
end
