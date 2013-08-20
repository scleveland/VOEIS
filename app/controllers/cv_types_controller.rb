class CvTypesController < Voeis::CVController
  rescue_from ActionView::MissingTemplate, :with => :invalid_page

  ###GLOBAL CVType controller
  before_filter do
    @cv_global = true
    @cv_class = Voeis::CVType
    @cv_type = :cv_type
    init(@cv_type,@cv_class,@cv_global)
  end
  
end