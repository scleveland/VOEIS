require 'responders/rql'

class MetaTagsController < InheritedResources::Base
  rescue_from ActionView::MissingTemplate, :with => :invalid_page
  responders :rql
  defaults  :route_collection_name => 'meta_tags',
            :route_instance_name => 'meta_tag',
            :collection_name => 'meta_tags',
            :instance_name => 'meta_tag',
            :resource_class => Voeis::MetaTag
          

  respond_to :html, :json
  
  # GET /meta_tags/new
  def new
    @meta_tag = Voeis::MetaTag.new
    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  # POST /meta_tags
  def create
    @meta_tag = Voeis::MetaTag.new(params[:meta_tag])
    respond_to do |format|
      if @meta_tag.save
        flash[:notice] = 'MetaTags was successfully created.'
        format.json do
          render :json => @meta_tag.as_json, :callback => params[:jsoncallback]
        end
        format.html { (redirect_to(meta_tag_path( @meta_tag.id))) }
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
