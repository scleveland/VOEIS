class Voeis::LabsController < Voeis::BaseController
  # Properly override defaults to ensure proper controller behavior
  # @see Voeis::BaseController
  defaults  :route_collection_name => 'labs',
            :route_instance_name => 'lab',
            :collection_name => 'labs',
            :instance_name => 'lab',
            :resource_class => Voeis::Lab

  def new
    @project = parent
    @labs = Voeis::Lab.all
  end

  def edit
    @lab =  parent.managed_repository{Voeis::Lab.get(params[:id])}
    @project = parent
  end

  def create
    parent.managed_repository do
      @lab = Voeis::Lab.new(params[:lab])
      respond_to do |format|
        if @lab.save
          format.json {
            render :json => @lab.as_json, :callback => params[:jsoncallback]
          }
          format.html {
            flash[:notice] = 'Lab was successfully created.'
            (redirect_to(new_project_lab_path()))
          }
          format.js
        else
          flash[:warning] = 'There was a problem saving the Lab.'
          format.html { render :action => "new" }
        end
      end
    end
  end

  def add_lab
    @labs = Voeis::Lab.all
  end

  def save_lab
    sys_lab = Voeis::Lab.first(:id => params[:lab])
    parent.managed_repository{Voeis::Lab.first_or_create(
      :lab_name => sys_lab.lab_name,         
      :lab_organization=> sys_lab.lab_organization,
      :lab_name=> sys_lab.lab_name,
      :lab_description=> sys_lab.lab_description,
      :lab_link=> sys_lab.lab_link)}

    redirect_to project_url(parent)
  end
end
