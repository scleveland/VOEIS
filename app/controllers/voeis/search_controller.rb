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
  
  end

end
