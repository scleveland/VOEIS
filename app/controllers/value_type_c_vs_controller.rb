class ValueTypeCVsController < ApplicationController
  rescue_from ActionView::MissingTemplate, :with => :invalid_page


  # GET /variables/new
  def new
    @value_type = Voeis::ValueTypeCV.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  # POST /variables
  def create
    @value_type = Voeis::ValueTypeCV.new(params[:value_type_c_v])
    respond_to do |format|
      if @value_type.save
        flash[:notice] = 'Value Type was successfully created.'
        format.html { (redirect_to(new_value_type_c_v_path())) }
        format.json do
          render :json => @value_type.as_json, :callback => params[:jsoncallback]
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