class Voeis::SearchController < Voeis::BaseController
  # Properly override defaults to ensure proper controller behavior
  # @see Voeis::BaseController
  
  def new
    @sites = parent.managed_repository{Voeis::Site.all}
    @variables = parent.managed_repository{Voeis::Variable.all}
    @units = Voeis::Unit.all
    @unit_names = Hash.new
    @units.map{|u| @unit_names = @unit_names.merge({u.id => u.units_name})}
  end
  
  def index
    site_ids    = params[:site_ids].split(',')
    variable_ids = params[:var_ids].split(',')
    start_date   = params[:start_date]
    end_date     = params[:end_date]
    
    data = parent.managed_repository {
      Voeis::DataValue.all(:variable_id => variable_ids, 
                            :site_id => site_ids,
                            :local_date_time.gte => start_date,
                            :local_date_time.lte => end_date)
    }

    results = []
    # result[timestamp] = {var_id=>val,var_id=>val,var_id=>val}
    data.each do |d|
      results[d.local_date_time] ||= {}
      results[d.local_date_time][d.variable_id] = d.data_value
    end
    
    @data = results.map{|k,v| {:timestamp => k}.merge(v) }
    @data = @data.sort{|a,b| a[:timestamp] <=> b[:timestamp] }
    
    @variables = parent.managed_repository {
      Voeis::Variable.all(:id => variable_ids)
    }
  end

end
