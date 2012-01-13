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
      
      @field_method.method_link = nil if @field_method.method_link.empty?
      if @field_method.his_id.empty?
        @field_method.his_id = nil
      else
        @field_method.his_id = params[:field_method][:his_id].to_i
      end
      
      respond_to do |format|
        if @field_method.save
          format.json {
            render :json => @field_method.as_json, :callback => params[:jsoncallback]
          }
          format.html {
            flash[:notice] = 'Field Method was successfully created.'
            (redirect_to(new_project_field_method_path()))
          }
          format.js
        else
          flash[:warning] = 'There was a problem saving the Field Method.'
          format.html { render :action => "new" }
        end
      end
    end
  end

end
