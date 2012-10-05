class QualityControlLevelsController  < Voeis::CVController
  rescue_from ActionView::MissingTemplate, :with => :invalid_page

  ###GLOBAL QualityControlLevel controller
  before_filter do
    @cv_global = true
    @cv_class = Voeis::QualityControlLevel
    @cv_type = :quality_control_level
    init(@cv_type,@cv_class,@cv_global)
  end
  
end