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
  
  respond_to :html, :json, :wml
  
  has_widgets do |root|
    root << widget(:versions)
  end

  
  @project = parent
  
  # def index
  #   
  #   sites = parent.managed_repository{Voeis::Site.all}
  #   respond_to do |format|
  #      format_response(sites, format)
  #   end
  # end
  # 
  def new
    @project = parent
    @sites = Voeis::Site.all
    
    #### CV stuff
    @vertical_datum_items = [['-none-', nil]]
    @local_projection_items = [['-none-', nil]]
    @vertical_datums = Voeis::VerticalDatumCV.all(:order => [:term.asc])
    #@vertical_datums_local = @project.managed_repository{Voeis::VerticalDatumCV.all(:order => [:term.asc])}
    @local_projections = Voeis::SpatialReference.all(:order => [:srs_name.asc])
    #@local_projections_local = @project.managed_repository{Voeis::LocalProjectionCV.all(:order => [:term.asc])}
    @vertical_datums.each { |item| @vertical_datum_items << [item.term, item.id.to_s] }
    @local_projections.each { |item| @local_projection_items << [item.srs_name, item.id.to_s] }
  end
  
  def show
    @site =  parent.managed_repository{Voeis::Site.get(params[:id])}
    @site_variable_stats = parent.managed_repository{Voeis::SiteDataCatalog.all(:site_id=>params[:id])}
    # debugger
    @versions = parent.managed_repository{Voeis::Site.get(params[:id]).versions}
    @site_ref = {}
    Voeis::Site.properties.each{|prop| @site_ref[prop.name] = @site[prop.name]}
    @site_ref[:lat_long_datum] = @site.lat_long_datum.nil? ? '-none-' : @site.lat_long_datum.srs_name
    @site_ref[:vertical_datum] = @site.vertical_datum.nil? ? '-none-' : @site.vertical_datum.term
    @site_ref[:local_projection] = @site.local_projection.nil? ? '-none-' : @site.local_projection.srs_name

    #@site_properties = @site.properties.map{ |prop| 
    #  prop = prop.name.to_s
    #  #if prop.name.to_s[-3..-1]=='_id'
    #  #  prop.name.to_s[0..-4]
    #  #  #@site_ref_props << prop
    #  #else
    #  #  prop.name.to_s
    #  #end
    #}
    @site_properties = [
      {:label=>"Site ID", :name=>"id"},
      {:label=>"Name", :name=>"name"},
      {:label=>"Code", :name=>"code"},
      {:label=>"Latitude", :name=>"latitude"},
      {:label=>"Longitude", :name=>"longitude"},
      {:label=>"Lat/Long Datum", :name=>"lat_long_datum"},
      {:label=>"Elevation", :name=>"elevation_m"},
      {:label=>"Local X", :name=>"local_x"},
      {:label=>"Local Y", :name=>"local_y"},
      {:label=>"Local Projection", :name=>"local_projection"},
      {:label=>"Vertical Datum", :name=>"vertical_datum"},
      {:label=>"Position Accuracy", :name=>"pos_accuracy_m"},
      {:label=>"State", :name=>"state"},
      {:label=>"County", :name=>"county"},
      {:label=>"Description", :name=>"description"},
      {:label=>"Comments", :name=>"comments"},
      {:label=>"HIS ID", :name=>"his_id"},
      {:label=>"Time Zone Offset", :name=>"time_zone_offset"},
      {:label=>"Updated", :name=>"updated_at"},
      {:label=>"Updated By", :name=>"updated_by"},
      {:label=>"Update Comment", :name=>"updated_comment"},
      {:label=>"Provenance Comment", :name=>"provenance_comment"},
      {:label=>"Created", :name=>"created_at"}
      ]
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
  
  def versions
    @project = parent
    @site =  parent.managed_repository{Voeis::Site.get(params[:id])}
    #@versions = parent.managed_repository{Voeis::Site.get(params[:id]).versions}
    #@versions = parent.managed_repository.adapter.select('SELECT * FROM voeis_site_versions WHERE id=%s ORDER BY updated_at DESC'%@site.id)
    ##@versions = @versions.to_a
    ##@versions = @site.versions
    @versions = @project.managed_repository{@site.versions_array}
    
    @site_refs = []
    temp = {}
    temp[:lat_long_datum] = '-none-'
    temp[:vertical_datum] = '-none-'
    temp[:local_projection] = '-none-'
    if !Voeis::SpatialReference.get(@site.lat_long_datum_id).nil?
      temp[:lat_long_datum] = Voeis::SpatialReference.get(@site.lat_long_datum_id).srs_name
    end
    if !Voeis::VerticalDatumCV.get(@site.vertical_datum_id).nil?
      temp[:vertical_datum] = Voeis::VerticalDatumCV.get(@site.vertical_datum_id).term
    end
    if !Voeis::SpatialReference.get(@site.local_projection_id).nil?
      temp[:local_projection] = Voeis::SpatialReference.get(@site.local_projection_id).srs_name
    end
    @site_refs << temp
    @versions.each{|ver| 
      temp = {}
      temp[:lat_long_datum] = '-none-'
      temp[:vertical_datum] = '-none-'
      temp[:local_projection] = '-none-'
      if !Voeis::SpatialReference.get(ver.lat_long_datum_id).nil?
        temp[:lat_long_datum] = Voeis::SpatialReference.get(ver.lat_long_datum_id).srs_name
      end
      if !Voeis::VerticalDatumCV.get(ver.vertical_datum_id).nil?
        temp[:vertical_datum] = Voeis::VerticalDatumCV.get(ver.vertical_datum_id).term
      end
      if !Voeis::SpatialReference.get(ver.local_projection_id).nil?
        temp[:local_projection] = Voeis::SpatialReference.get(ver.local_projection_id).srs_name
      end
      @site_refs << temp
    }

    @ver_properties = [
#      {:label=>"Version", :name=>"version"},
#      {:label=>"Site ID", :name=>"id"},
      {:label=>"Name", :name=>"name"},
      {:label=>"Code", :name=>"code"},
      {:label=>"Latitude", :name=>"latitude"},
      {:label=>"Longitude", :name=>"longitude"},
      {:label=>"Lat/Long Datum", :name=>"lat_long_datum"},
      {:label=>"Elevation", :name=>"elevation_m"},
      {:label=>"Local X", :name=>"local_x"},
      {:label=>"Local Y", :name=>"local_y"},
      {:label=>"Local Projection", :name=>"local_projection"},
      {:label=>"Vertical Datum", :name=>"vertical_datum"},
      {:label=>"Position Accuracy", :name=>"pos_accuracy_m"},
      {:label=>"State", :name=>"state"},
      {:label=>"County", :name=>"county"},
      {:label=>"Description", :name=>"description"},
      {:label=>"Comments", :name=>"comments"},
      {:label=>"HIS ID", :name=>"his_id"}
#      {:label=>"Updated By", :name=>"updated_by_name"},
#      {:label=>"Update Comment", :name=>"updated_comment"},
#      {:label=>"Provenance Comment", :name=>"provenance_comment"}
      ]
    ###
    #render 'versions2.html.haml'
  end
  
  def edit
    @site =  parent.managed_repository{Voeis::Site.get(params[:id])}
  end
  
  def update
    # This should be handled by the framework, but isn't when using jruby.
    params[:site][:latitude] = params[:site][:latitude].strip.to_f
    params[:site][:longitude] = params[:site][:longitude].strip.to_f
    #@vert_datum_global = Voeis::VerticalDatumCV.get(params[:site][:vertical_datum_id].to_i)
    #@local_proj_global = Voeis::LocalProjectionCV.get(params[:site][:local_projection_id].to_i)
    
    parent.managed_repository{
      site = Voeis::Site.get(params[:site][:id])
      
      params[:site].each do |key, value|
        site[key] = value.blank? ? nil : value
      end
      site.updated_at = Time.now
      site.lat_long_datum_id = params[:site][:lat_long_datum_id] == "NaN" ? nil : params[:site][:lat_long_datum_id].to_i
      site.vertical_datum_id = params[:site][:vertical_datum_id] == "NaN" ? nil : params[:site][:vertical_datum_id].to_i
      site.local_projection_id = params[:site][:local_projection_id] == "NaN" ? nil : params[:site][:local_projection_id].to_i
      puts site.valid?
      puts site.errors.inspect
      
      #### CV update -- global -> local
      # if @vert_datum_global.nil?
      #         site.vertical_datum = nil
      #       else
      #         site.vertical_datum = Voeis::VerticalDatumCV.first_or_create(:id=>@vert_datum_global.id,
      #                                                           :term=>@vert_datum_global.term,
      #                                                           :definition=>@vert_datum_global.definition)
      #       end
      #       #site.vertical_datum = vert_datum
      #       if @local_proj_global.nil?
      #         site.local_projection = nil
      #       else
      #         site.local_projection = Voeis::LocalProjectionCV.first_or_create(:id=>@local_proj_global.id,
      #                                                           :term=>@local_proj_global.term,
      #                                                           :definition=>@local_proj_global.definition)
      # end
      #site.local_projection = local_proj
      respond_to do |format|
        if site.save
          format.html{
            flash[:notice] = "Site was Updated successfully."
            redirect_to project_url(parent)
          }
          format.json{
            render :json => site.as_json, :callback => params[:jsoncallback]
          }
        end
      end
    }
    ### update! do |success, failure|
    #       success.html { redirect_to project_url(parent) }
    #     end
  end

  # graphs
  # display graphs for all variables for at least the last 24 hours
  #
  def graphs
    @units = Voeis::Unit.all()
    parent.managed_repository do
      @site =  Voeis::Site.get(params[:site_id])
      #fetch all variables that have measurements for this site
      @site_catalog_items = Voeis::SiteDataCatalog.all(:site_id => @site.id, :record_number.gt => 0)
      @variables = Voeis::Variable.all(:id => @site_catalog_items.map{|v| v.variable_id})
      @graph_data = {}
      @variables.each do |var|
        @graph_data[var.id.to_s] = var.values_graph(@site, params[:number].nil? ? 12 : params[:number].to_i)
      end
      
      # respond_to do |format|
      #   format.html{
      #     flash[:notice] = "Site was Updated successfully."
      #     redirect_to project_url(parent)
      #   }
      #   format.json{
      #     render :json => site.as_json, :callback => params[:jsoncallback]
      #   }
      # end #end format
    end #end repository
  end

  def create
    @project = parent
    # This should be handled by the framework, but isn't when using jruby.
    params[:site][:latitude] = params[:site][:latitude].strip
    params[:site][:longitude] = params[:site][:longitude].strip
    #@vert_datum_global = Voeis::VerticalDatumCV.get(params[:site][:vertical_datum_id].to_i)
    #@local_proj_global = Voeis::LocalProjectionCV.get(params[:site][:local_projection_id].to_i)
    
    @project.managed_repository{ 
      site = Voeis::Site.new

      logger.debug('PARAMS:')
      params[:site].each do |key, value|
        logger.debug('KEY: '+key+' / VALUE: '+value)
        site[key] = value.empty? ? nil : value
      end
      #if key!='vertical_datum' && key!='local_projection'
      #  site[key] = params[:site][key].empty? ? nil : params[:site][key]
      #end
      #site.lat_long_datum_id = params[:site][:lat_long_datum] == "NaN" ? nil : params[:site][:lat_long_datum].to_i
      #site.vertical_datum_id = params[:site][:vertical_datum] == "NaN" ? nil : params[:site][:vertical_datum].to_i
      #site.local_projection_id = params[:site][:local_projection] == "NaN" ? nil : params[:site][:local_projection].to_i
      site.updated_at = Time.now
      site.lat_long_datum_id = params[:site][:lat_long_datum_id] == "NaN" ? nil : params[:site][:lat_long_datum_id].to_i
      site.vertical_datum_id = params[:site][:vertical_datum_id] == "NaN" ? nil : params[:site][:vertical_datum_id].to_i
      site.local_projection_id = params[:site][:local_projection_id] == "NaN" ? nil : params[:site][:local_projection_id].to_i
      #### CV update -- global -> local
      # if @vert_datum_global.nil?
      #   site.vertical_datum = nil
      # else
      #   site.vertical_datum = Voeis::VerticalDatumCV.first_or_create(:id=>@vert_datum_global.id,
      #                                                     :term=>@vert_datum_global.term,
      #                                                     :definition=>@vert_datum_global.definition)
      # end
      # if @local_proj_global.nil?
      #   site.local_projection = nil
      # else
      #   site.local_projection = Voeis::LocalProjectionCV.first_or_create(:id=>@local_proj_global.id,
      #                                                     :term=>@local_proj_global.term,
      #                                                     :definition=>@local_proj_global.definition)
      # end
      respond_to do |format|
        if site.save
          format.html{
            flash[:notice] = "New Site was saved successfully."
            redirect_to project_url(parent)
          }
          format.json{
            render :json => site.as_json, :callback => params[:jsoncallback]
          }
        end
      end
    }
    #create! do |success, failure|
    #  success.html { redirect_to project_url(parent) }
    #end
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
  
  private
  
  
  def format_response(data_obj, format)
    format.json do
      render :json => data_obj.as_json, :callback => params[:jsoncallback]
    end
    format.xml do
      render :xml => data_obj.to_xml
    end
    format.csv do
      render :text => data_obj.to_csv.to_s.gsub(/\n\n/, "\n")
    end
    format.wml do 
      render :xml => data_obj.to_wml
    end
  end
  
end
