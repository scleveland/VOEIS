class LocalProjectionCVsController < ApplicationController
  rescue_from ActionView::MissingTemplate, :with => :invalid_page


  # GET /variables/new
  def new
    @local_projection = Voeis::LocalProjectionCV.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  # POST /variables
  def create
    @local_projection = Voeis::LocalProjectionCV.new(params[:variable_name_c_v])
    respond_to do |format|
      if @local_projection.save
        flash[:notice] = 'Local Projection was successfully created.'
        format.html { (redirect_to(new_local_projection_c_v_path())) }
        format.json do
          render :json => @local_projection.as_json, :callback => params[:jsoncallback]
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