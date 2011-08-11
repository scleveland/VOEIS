require 'responders/rql'

class Voeis::SitesController < Voeis::BaseController
  # Properly override defaults to ensure proper controller behavior
  # @see Voeis::BaseController
  responders :rql
  defaults  :route_collection_name => 'sites',
            :route_instance_name => 'site',
            :collection_name => 'sites',
            :instance_name => 'site',
            :resource_class => Voeis::Site
   
  has_widgets do |root|
    root << widget(:vertical_datum)
  end
  
  @project = parent
  
  def new
    @sites = Voeis::Site.all
  end
  
  def show
    @site =  parent.managed_repository{Voeis::Site.get(params[:id])}
    @site_variable_stats = parent.managed_repository{Voeis::SiteDataCatalog.all(:site_id=>@site.id)}
    # debugger
    #@versions = parent.managed_repository{Voeis::Site.get(params[:id]).versions}

    @site_properties = @site.properties.map{ |prop| 
      prop = prop.name.to_s
      #if prop.name.to_s[-3..-1]=='_id'
      #  prop.name.to_s[0..-4]
      #  #@site_ref_props << prop
      #else
      #  prop.name.to_s
      #end
    }
    #@site_properties << 'vertical_datum'
    #@site_properties << 'local_projection'

    @sites = parent.managed_repository{Voeis::Site.all}
    @label_array = Array["Sample Type","Lab Sample Code","Sample Medium","Timestamp"]
    @field_array = Array["sample_type","lab_sample_code","material","local_date_time"]
    @current_samples = Array.new
    @samples = @site.samples
    @samples.all(:order => [:lab_sample_code.asc]).each do |samp|
       @temp_array = Array.new
       @temp_array=Array[samp.sample_type, samp.lab_sample_code, samp.material, samp.local_date_time.to_s]
       @current_samples << @temp_array
    end
    show!
  end
  
  def edit
    @site =  parent.managed_repository{Voeis::Site.get(params[:id])}
  end
  
  def update
    params[:site][:latitude] = params[:site][:latitude].strip
    params[:site][:longitude] = params[:site][:longitude].strip
    @vert_datum_global = Voeis::VerticalDatumCV.get(params[:vertical_datum_id])
    @local_proj_global = Voeis::LocalProjectionCV.get(params[:local_projection_id])
    
    parent.managed_repository do 
      site = Voeis::Site.get(params[:id])
      params[:site].each do |key, value|
        site[key] = value.empty? ? nil : value
      end
      site.updated_at = Time.now
      puts site.valid?
      puts site.errors.inspect()
      #### CV update -- global -> local
      vert_datum = Voeis::VerticalDatumCV.first_or_create(:id=>@vert_datum_global.id,
                                                          :term=>@vert_datum_global.term,
                                                          :definition=>@vert_datum_global.definition)
      site.vertical_datum = vert_datum
      local_proj = Voeis::LocalProjectionCV.first_or_create(:id=>@local_proj_global.id,
                                                          :term=>@local_proj_global.term,
                                                          :definition=>@local_proj_global.definition)
      site.local_projection = local_proj
      if site.save
         flash[:notice] = "Site was Updated successfully."
         redirect_to project_url(parent)
      end
    end
    
    ### update! do |success, failure|
    #       success.html { redirect_to project_url(parent) }
    #     end
    
  end

  def create
    # This should be handled by the framework, but isn't when using jruby.
    params[:site][:latitude] = params[:site][:latitude].strip
    params[:site][:longitude] = params[:site][:longitude].strip
    params[:site].each_key do |key|
      params[:site][key] = params[:site][key].empty? ? nil : params[:site][key]
    end
    create! do |success, failure|
      success.html { redirect_to project_url(parent) }
    end
  end

  def add_site
    @sites = Voeis::Site.all
  end

  def save_site
    sys_site = Voeis::Site.first(:id => params[:site])
    parent.managed_repository{Voeis::Site.first_or_create(
                :code => sys_site.site_code,
                :name => sys_site.site_name,
                :latitude => sys_site.latitude,
                :longitude  => sys_site.longitude,
                # :lat_long_datum_id => sys_site.lat_long_datum_id,
                # :elevation_m => sys_site.elevation_m,
                # :vertical_datum => sys_site.vertical_datum,
                # :local_x => sys_site.local_x,
                # :local_y => sys_site.local_y,
                # :local_projection_id => sys_site.local_projection_id,
                # :pos_accuracy_m => sys_site.pos_accuracy_m,
                :state => sys_site.state)}
                # :county => sys_site.county,
                # :comments => sys_site.comments)}

    redirect_to project_url(parent)
  end

  # site_samples 
  # Returns the samples for a given site
  #
  #
  # @example http://voeis.msu.montana.edu/projects/e787bee8-e3ab-11df-b985-002500d43ea0/site/site_sample.json?site_id=1
  # 
  # @param [Integer] :site_id the id of the site within the project
  # 
  # @return [JSON String] an array of samples that exist for the projects site and each ones properties and values
  #
  # @author Sean Cleveland
  #
  # @api public
  def site_samples
    @samples = Hash.new
    parent.managed_repository do
      site = Voeis::Site.get(params[:site_id])
      @samples ={"samples" => site.samples.all(:order => [:lab_sample_code.asc])}
    end
    respond_to do |format|
       format.json do
         format.html
         render :json => @samples.as_json, :callback => params[:jsoncallback]
       end
     end
  end
end
