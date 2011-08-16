class VerticalDatumCVsController < ApplicationController
  rescue_from ActionView::MissingTemplate, :with => :invalid_page


  # GLOBAL: GET /VerticalDatum/new
  def new
    @vertical_datum = Voeis::VerticalDatumCV.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  # POST /VerticalDatum
  def create
    @vertical_datum = Voeis::VerticalDatumCV.new(params[:vertical_datum_c_v])
    #debugger
    respond_to do |format|
      if @vertical_datum.save
        flash[:notice] = 'Vertical Datum was successfully created.'
        format.html { (redirect_to(new_vertical_datum_c_v_path())) }
        format.json do
          render :json => @vertical_datum.as_json, :callback => params[:jsoncallback]
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