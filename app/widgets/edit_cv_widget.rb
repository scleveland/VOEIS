class EditCvWidget < Apotomo::Widget
  responds_to_event :submit, :with=>:update_site

  def display(options = {})
    ### FORM INPUT TYPES from controller: CV_FORM
    ### CV_FORM[:type] ("B2-XTA")
    ###      type: XTA = X:model type (not in model) -- TA:widget (Textarea)
    ###      model type: X:non-model -- I:integer -- N:number -- F:float -- S:string -- B:boolean
    ###      type B2 = preceed with 2x breaks (<br />)
    ###      2B preceed with 2x <br />
    ###      3S preceed with 3x &nbsp;
    @types = {:H=>{:type=>"hidden", :dojo=>""},
              :TB=>{:type=>"text", :dojo=>"dijit.form.ValidationTextBox"},
              :NB=>{:type=>"text", :dojo=>"dijit.form.NumberTextBox"},
              :DB=>{:type=>"text", :dojo=>"dijit.form.DateTextBox"},
              :TA=>{:type=>"text", :dojo=>"dijit.form.SimpleTextarea"},
              :TA1=>{:type=>"text", :dojo=>"dijit.form.Textarea"},
              :TA2=>{:type=>"text", :dojo=>"dijit_ext.ValidationTextarea"},
              :CK=>{:type=>"checkbox", :dojo=>"dijit.form.CheckBox"},
              :L=>{:type=>"", :dojo=>""}}   ###LABEL
    @delims = {:B=>'<br style="float:none;clear:both;"  />', :S=>'&nbsp;'}
    
    ###############
    @project = options[:project]
    @tabId = options[:tabId]
    @cv_data = options[:cv_data]
    @copy_data = options[:copy_data]
    @cv_title = options[:cv_title]
    @cv_title2 = options[:cv_title2]
    @cv_title2cv = options[:cv_title2cv]
    @cv_id = options[:cv_id]
    @cv_name = options[:cv_name]
    @cv_columns = options[:cv_columns]
    @copy_columns = options[:copy_columns]
    @cv_form = options[:cv_form]
    @global = options[:global]
    
    ####
    @current_user = options[:user]
    #@auth = !@current_user.nil? && @current_user.projects.include?(@project)
    #@root_url = options[:root_url]
    #@id = UUIDTools::UUID.timestamp_create
    ####
    ####
    render
  end
  
private
  def setup
    #@test = options[:test]
  end
end
