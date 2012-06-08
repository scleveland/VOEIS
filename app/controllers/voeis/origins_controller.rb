require 'responders/rql'
class Voeis::OriginsController < Voeis::BaseController  
  responders :rql
  respond_to :html, :json
  defaults  :route_collection_name => 'origins',
            :route_instance_name => 'origin',
            :collection_name => 'origins',
            :instance_name => 'origin',
            :resource_class => Voeis::Origin
            
  def create
    debugger
    parent.managed_repository do
      origin = Voeis::Origin.new(params[:origin])
      respond_to do |format|
        if origin.save
          format.html{
            flash[:notice] = "New Origin was saved successfully."
            redirect_to project_url(parent)
          }
          format.json{
            render :json => origin.as_json, :callback => params[:jsoncallback]
          }
        end
      end
    end
  end
end
