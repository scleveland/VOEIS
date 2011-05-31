class Voeis::FieldMethodsController < Voeis::BaseController
  # Properly override defaults to ensure proper controller behavior
  # @see Voeis::BaseController
  defaults  :route_collection_name => 'field_methods',
            :route_instance_name => 'field_method',
            :collection_name => 'field_methods',
            :instance_name => 'field_method',
            :resource_class => Voeis::FieldMethod

  def new
    @project = parent
    @field_methods = Voeis::FieldMethod.all
  end

  def edit
    @field_method =  parent.managed_repository{Voeis::FieldMethod.get(params[:id])}
    @project = parent
  end

  def create
    parent.managed_repository do
      @field_method = Voeis::FieldMethod.new(params[:field_method])
  
      respond_to do |format|
        if @field_method.save
          flash[:notice] = 'Field Method was successfully created.'
           format.json do
              render :json => @field_method.as_json, :callback => params[:jsoncallback]
            end
          format.html { (redirect_to(new_project_field_method_path())) }
          format.js
        else
          format.html { render :action => "new" }
        end
      end
    end
  end

end
