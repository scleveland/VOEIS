- content_for(:javascripts) do
  :javascript
    function createFieldMethod(){ 
    $.post("#{root_url + "lab_methods"}.json?filed_method[method_name]=" +$("#field_method_method_name").val()+&field_method[method_description]="+$("#field_method_method_description").val() + "&field_method[method_link]="+ $("#field_method_method_link").val(),
    function(data) {
      $('#variable_field_method').append($("<option></option>").attr("value",data['id']).text($("#field_method_method_name").val())); 
      $('#variable_field_method').val(data['id']);
      dijit.byId("new_field_method1").hide();
    }
    );
    }
    dojo.require("dijit.Tooltip");

#new_field_method1{:dojoType=>"dijit.Dialog", :title=>"New Field Method"}
  %h3 Create a new Lab Method:
  = form_for (:field_method) do |f|
    = f.label("Field Method Name:")
    =clear_break
    =f.text_field :method_name, :size=> 50
    =clear_break
    =f.text_field :method_description, :size=> 50
    =clear_break
    = f.label("Lab Method Link:")
    =clear_break
    =f.text_field :method_link, :size=> 50
    =clear_break
    %button{:id=> 'new_field_method_button',:dojoType=>"dijit.form.Button", :title=>'Create', :onClick=>"createFieldMethod();"}
      Create Method




