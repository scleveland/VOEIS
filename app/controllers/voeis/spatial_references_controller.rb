class Voeis::SpatialReferencesController < Voeis::BaseController
  rescue_from ActionView::MissingTemplate, :with => :invalid_page


  # LOCAL: GET /LocalProjection/new
  def new
    @spatial_reference = parent.managed_repository{Voeis::SpatialReference.new}

    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  # POST /LocalProjection
  def create
    @spatial_reference = parent.managed_repository{Voeis::SpatialReference.new(params[:spatial_reference])}
    respond_to do |format|
      if @spatial_reference.save
        flash[:notice] = 'Local Projection was successfully created.'
        format.html { (redirect_to(new_spatial_reference_path())) }
        format.json do
          render :json => @spatial_reference.as_json, :callback => params[:jsoncallback]
        end
      else
        format.html { render :action => "new" }
      end
    end
  end
  
  def show
    
  end

  def invalid_page
    redirect_to(:back)
  end
end