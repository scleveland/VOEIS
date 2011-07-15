class LabsController < ApplicationController
  rescue_from ActionView::MissingTemplate, :with => :invalid_page


  # GET /labs/new
  def new
    @lab = Voeis::Lab.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  # POST /labs
  def create
    @lab = Voeis::Lab.new(params[:lab])
    respond_to do |format|
      if @lab.save
        flash[:notice] = 'Lab Method was successfully created.'
        format.json do
          render :json => @lab.as_json, :callback => params[:jsoncallback]
        end
        format.html { (redirect_to(new_lab_c_v_path())) }
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