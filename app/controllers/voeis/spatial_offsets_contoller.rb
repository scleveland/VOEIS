require 'responders/rql'

class SpatialOffsetsController < InheritedResources::Base
  rescue_from ActionView::MissingTemplate, :with => :invalid_page
  responders :rql
  defaults  :route_collection_name => 'spatial_offsets',
            :route_instance_name => 'spatial_offset',
            :collection_name => 'spatial_offsets',
            :instance_name => 'spatial_offset',
            :resource_class => Voeis::SpatialOffset

  respond_to :html, :json
  
  # GET /spatial_offsets/new
  def new
    @spatial_offset = Voeis::SpatialOffset.new
    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  # POST /spatial_offsets
  def create

    @spatial_offset = Voeis::SpatialOffset.new(params[:spatial_offset])
    respond_to do |format|
      if @spatial_offset.save
        flash[:notice] = 'Spatial Offset was successfully created.'
        format.json do
          render :json => @spatial_offset.as_json, :callback => params[:jsoncallback]
        end
        format.html { (redirect_to(spatial_offset_path( @spatial_offset.id))) }
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
