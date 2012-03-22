class Voeis::SearchController < Voeis::BaseController
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
    @tabId = params[:tab_id]
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
    #@variables = ""
    parent.managed_repository do
      data =Voeis::DataValue.all(:variable_id => variable_ids, 
                            :site_id => site_ids,
                            :local_date_time.gte => start_date,
                            :local_date_time.lte => end_date)
     # @variables  = data.variables(:unique=>true)
    end
    @dv_count = data.count
    results = {}
    presults = {}
    @variables=[]
    var_ids = []
    #var_ids=data.map{|d| d.variable.id}
    # result[timestamp] = {var_id=>val,var_id=>val,var_id=>val}
    data.each do |d|
      results[d.local_date_time] ||= {}
      results[d.local_date_time][d.variable_id] = d.data_value
      presults[d.local_date_time.strftime("%Y%m%d%H%M").to_i] ||= {}
      presults[d.local_date_time.strftime("%Y%m%d%H%M").to_i]["var_#{d.variable_id}"] = d.data_value
      #@variables << d.variable unless @variables.include?(d.variable)
      @variables << d.variable.to_hash.update({:site_id=>d.site_id}) unless var_ids.include?(d.variable.id)
      var_ids << d.variable.id
    end
    null_variables={}
    if !@variables.empty?
      @variables.each do |v|
        if !v.nil?
          null_variables["var_#{v['id']}"] = -9999
        end
      end
    end
    @parallel_results=[]
    presults.each do |k,pr| 
      @parallel_results << {:timestamp => k}.merge(null_variables.merge(pr))
    end
    @data = results.map{|k,v| {:timestamp => k}.merge(v) }
   # @parallel_results = presults.map{|k,v| {:timestamp => k}.merge(v) }
    @data = @data.sort{|a,b| a[:timestamp] <=> b[:timestamp] }
    
    # @variables = parent.managed_repository {
    #   Voeis::Variable.all(:id => variable_ids)
    # }
  end
  
  #export the results of search/browse to a csv file
  def export
    filename ="voeis_data.csv"
    send_data(params[:data],
      :type => 'text/csv; charset=utf-8; header=present',
      :filename => filename)
  end

end
