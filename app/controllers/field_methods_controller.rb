class FieldMethodsController < ApplicationController
  rescue_from ActionView::MissingTemplate, :with => :invalid_page


  # GET /field_methods/new
  def new
    @field_method = Voeis::FieldMethod.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  # POST /field_methods
  def create
    @field_method = Voeis::FieldMethod.new(params[:field_method])
    
    respond_to do |format|
      if @field_method.save
        flash[:notice] = 'Field Method was successfully created.'
        format.html { (redirect_to(new_field_method_c_v_path())) }
        format.json do
          render :json => @field_method.as_json, :callback => params[:jsoncallback]
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