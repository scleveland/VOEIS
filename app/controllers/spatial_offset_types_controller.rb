require 'responders/rql'

class SpatialOffsetTypesController < InheritedResources::Base
  rescue_from ActionView::MissingTemplate, :with => :invalid_page
  responders :rql
  defaults  :route_collection_name => 'spatial_offset_types',
            :route_instance_name => 'spatial_offset_type',
            :collection_name => 'spatial_offset_types',
            :instance_name => 'spatial_offset_type',
            :resource_class => Voeis::SpatialOffsetType

  respond_to :html, :json
  
  # GET /spatial_offset_types/new
  def new
    @spatial_offset_type = Voeis::SpatialOffsetType.new
    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  # POST /spatial_offset_types
  def create

    @spatial_offset_type = Voeis::SpatialOffsetType.new(params[:spatial_offset_type])
    respond_to do |format|
      if @spatial_offset_type.save
        flash[:notice] = 'SpatialOffsetTypes was successfully created.'
        format.json do
          render :json => @spatial_offset_type.as_json, :callback => params[:jsoncallback]
        end
        format.html { (redirect_to(spatial_offset_type_path( @spatial_offset_type.id))) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # def show
  #   respond_to do |format|
  #     format.json do
        
  #     end
  #   end
  # end
  


  def invalid_page
    redirect_to(:back)
  end
end
