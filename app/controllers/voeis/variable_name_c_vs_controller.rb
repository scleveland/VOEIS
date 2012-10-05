class Voeis::VariableNameCVsController < Voeis::CVController
  rescue_from ActionView::MissingTemplate, :with => :invalid_page

  ###LOCAL VariableNameCV controller
  before_filter do
    @cv_global = false
    @cv_class = Voeis::VariableNameCV
    @cv_type = :variable_name
    init(@cv_type,@cv_class,@cv_global)
  end
  
end