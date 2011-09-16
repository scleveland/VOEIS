class Voeis::DataSetsController < Voeis::BaseController
  # Properly override defaults to ensure proper controller behavior
  # @see Voeis::BaseController
  defaults  :route_collection_name => 'data_sets',
            :route_instance_name => 'data_set',
            :collection_name => 'data_sets',
            :instance_name => 'data_set',
            :resource_class => Voeis::DataSet

  def new
    @project = parent
    @data_sets = Voeis::DataSet.all
  end

  def edit
    @data_set =  parent.managed_repository{Voeis::DataSet.get(params[:id])}
    @project = parent
  end

  def create
    parent.managed_repository do
      @data_set = Voeis::DataSet.new(params[:data_set])
      respond_to do |format|
        if @data_set.save
          flash[:notice] = 'DataSet Method was successfully created.'
           format.json do
              render :json => @data_set.as_json, :callback => params[:jsoncallback]
            end
          format.html { (redirect_to(new_project_data_set_path())) }
          format.js
        else
          format.html { render :action => "new" }
        end
      end
    end
  end

  def add_data_set
    @data_sets = Voeis::DataSet.all
  end

  def save_data_set
    sys_data_set = Voeis::DataSet.first(:id => params[:data_set])
    parent.managed_repository{Voeis::DataSet.first_or_create(
      :data_set_name => sys_data_set.data_set_name,         
      :data_set_organization=> sys_data_set.data_set_organization,
      :data_set_name=> sys_data_set.data_set_name,
      :data_set_description=> sys_data_set.data_set_description,
      :data_set_link=> sys_data_set.data_set_link)}

    redirect_to project_url(parent)
  end
end
