class Voeis::EquipmentController < Voeis::BaseController
  # Properly override defaults to ensure proper controller behavior
  # @see Voeis::BaseController
  defaults  :route_collection_name => 'equipment',
            :route_instance_name => 'equipment',
            :collection_name => 'equipment',
            :instance_name => 'equipment',
            :resource_class => Voeis::Equipment

  def new
    @project = parent
    @equipment = Voeis::Equipment.all
  end

  def edit
    @equipment =  parent.managed_repository{Voeis::Equipment.get(params[:id])}
    @project = parent
  end

  def create
    parent.managed_repository do

      @equipment = Voeis::Equipment.new(params[:equipment])
      respond_to do |format|
        if @equipment.save
          flash[:notice] = 'Equipment was successfully created.'
           format.json do
              render :json => @equipment.as_json, :callback => params[:jsoncallback]
            end
          format.html { (redirect_to(new_project_equipment_path())) }
          format.js
        else
          format.html { render :action => "new" }
        end
      end
    end
  end

  
end
