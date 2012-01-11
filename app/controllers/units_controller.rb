require 'responders/rql'
class UnitsController < InheritedResources::Base
  rescue_from ActionView::MissingTemplate, :with => :invalid_page
    responders :rql
  # Properly override defaults to ensure proper controller behavior
   # @see Voeis::BaseController
   defaults  :route_collection_name => 'units',
             :route_instance_name => 'unit',
             :collection_name => 'units',
             :instance_name => 'unit',
             :resource_class => Voeis::Unit
             

  respond_to :html, :json
  # GET /variables/new
  def new
    if current_user.system_role.name.eql?('Administrator')
      @unit = Voeis::Unit.new
      respond_to do |format|
        format.html # new.html.erb
      end
    else
      redirect_to('/')
    end
  end
  # POST /variables
  def create
    @unit = Voeis::Unit.new(params[:unit])

    if @unit.save  
      flash[:notice] = 'Unit was successfully created.'
      respond_to do |format|
        format.html { redirect_to( :action => "new" )}
      end
    else
      respond_to do |format|
        flash[:warning] = 'There was a problem saving the Unit.'
        format.html { render :action => "new" }
      end
    end
  end
  
  def invalid_page
    redirect_to(:back)
  end
end
