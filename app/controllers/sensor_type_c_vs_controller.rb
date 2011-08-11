class SensorTypeCVsController < ApplicationController
  rescue_from ActionView::MissingTemplate, :with => :invalid_page


  # GET /variables/new
  def new
    @sensor_type = Voeis::SensorTypeCV.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  # POST /variables
  def create
    @sensor_type = Voeis::SensorTypeCV.new(params[:sensor_type_c_v])
    respond_to do |format|
      if @sensor_type.save
        flash[:notice] = 'Sensor Type was successfully created.'
        format.html { (redirect_to(new_sensor_type_c_v_path())) }
        format.json do
          render :json => @sensor_type.as_json, :callback => params[:jsoncallback]
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