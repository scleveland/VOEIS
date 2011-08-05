class LoggerTypeCVsController < ApplicationController
  rescue_from ActionView::MissingTemplate, :with => :invalid_page


  # GET /variables/new
  def new
    @logger_type = Voeis::LoggerTypeCV.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  # POST /variables
  def create
    @logger_type = Voeis::LoggerTypeCV.new(params[:logger_type_c_v])
    respond_to do |format|
      if @logger_type.save
        flash[:notice] = 'Logger Type was successfully created.'
        format.html { (redirect_to(new_logger_type_c_v_path())) }
        format.json do
          render :json => @logger_type.as_json, :callback => params[:jsoncallback]
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