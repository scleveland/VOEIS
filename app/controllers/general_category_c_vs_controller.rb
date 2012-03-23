class GeneralCategoryCVsController < ApplicationController
  rescue_from ActionView::MissingTemplate, :with => :invalid_page

  has_widgets do |root|
    root << widget(:versions)
    root << widget(:edit_cv)
  end


  # GET /variables/new
  def new
    @general_category = Voeis::GeneralCategoryCV.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  # POST /variables
  def create
    if params[:general_category_c_v].nil?
      @general_category = Voeis::GeneralCategoryCV.new(:term=> params[:term], :definition => params[:definition])
    else
      @general_category = Voeis::GeneralCategoryCV.new(params[:general_category_c_v])
    end
    respond_to do |format|
      if @general_category.save
        flash[:notice] = 'General Category was successfully created.'
        format.html { (redirect_to(new_general_category_c_v_path())) }
        format.json do
          render :json => @general_category.as_json, :callback => params[:jsoncallback]
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