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
    parent.managed_repository do
      @jobs = Voeis::Job.all
      @job_array = Array.new
      @jobs.each do |j|
        j.check_status
        job_temp = Hash.new
        debugger
        job_temp = j.attributes.merge({:user_name => j.user_name, :filename=>JSON.parse(j.job_parameters)["parameters"]["datafile"]["original_filename"]})
        @job_array << job_temp
      end
    end
  end

  def invalid_page
    redirect_to(:home)
  end
end