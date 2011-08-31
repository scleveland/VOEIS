require 'responders/rql'

class VariablesController < InheritedResources::Base
  rescue_from ActionView::MissingTemplate, :with => :invalid_page
  responders :rql
  defaults  :route_collection_name => 'variables',
            :route_instance_name => 'variable',
            :collection_name => 'variables',
            :instance_name => 'variable',
            :resource_class => Voeis::Variable

  respond_to :html, :json
  
  # GET /variables/new
  def new
    @variable = Voeis::Variable.new
    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  # POST /variables
  def create
     @variable = Voeis::Variable.new(params[:variable])
     if @variable.variable_code.nil? || @variable.variable_code =="undefined"
       @variable.variable_code = @variable.id.to_s+@variable.variable_name+@variable.speciation+Voeis::Unit.get(@variable.variable_units_id).units_name
     end
     if params[:variable][:detection_limit].empty?
       @variable.detection_limit = nil
     end
     if params[:variable][:field_method_id].empty?
       @variable.field_method_id = nil
     end
     if params[:variable][:lab_id].empty?
       @variable.lab_id = nil
     end
     if params[:variable][:lab_method_id].empty?
       @variable.lab_method_id = nil
     end
     if params[:variable][:spatial_offset_type].empty?
       @variable.spatial_offset_type = nil
     end
     @variable.valid?
     puts "**************************************************************************************"
     puts @variable.errors.inspect()
    respond_to do |format|
      if @variable.save
        flash[:notice] = 'Variables was successfully created.'
        format.json do
          render :json => @variable.as_json, :callback => params[:jsoncallback]
        end
        format.html { (redirect_to(variable_path( @variable.id))) }
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
