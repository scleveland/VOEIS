class SpeciationCVsController < ApplicationController
  rescue_from ActionView::MissingTemplate, :with => :invalid_page


  # GET /variables/new
  def new
    @speciation = Voeis::SpeciationCV.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  # POST /variables
  def create
    @speciation = Voeis::SpeciationCV.new(params[:speciation_c_v])
    respond_to do |format|
      if @speciation.save
        flash[:notice] = 'Speciation was successfully created.'
        format.html { (redirect_to(new_speciation_c_v_path())) }
        format.json do
          render :json => @speciation.as_json, :callback => params[:jsoncallback]
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