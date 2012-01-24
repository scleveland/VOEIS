class Voeis::SearchController < Voeis::BaseController
  # Properly override defaults to ensure proper controller behavior
  # @see Voeis::BaseController
  
  def index
    @sites = parent.managed_repository{Voeis::Site.all}
    @variables = parent.managed_repository{Voeis::Variable.all}
  end

end
