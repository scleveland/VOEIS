require 'responders/rql'
class Voeis::JobsController < Voeis::BaseController
  rescue_from ActionView::MissingTemplate, :with => :invalid_page
  responders :rql
  defaults  :route_collection_name => 'jobs',
            :route_instance_name => 'job',
            :collection_name => 'jobs',
            :instance_name => 'job',
            :resource_class => Voeis::Job
            
  respond_to :html, :json
  def show
    render params[:id]
  end
  
  def index
    @jobs  = parent.managed_repository{Voeis::Job.all}
    @job_array = Array.new
    @jobs.each do |j|
      job_temp = Hash.new
      job_temp = j.attributes.merge({:user_name => j.user_name})
      @job_array << job_temp
    end
  end

  def invalid_page
    redirect_to(:home)
  end
end