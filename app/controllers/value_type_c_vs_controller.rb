class ValueTypeCVsController < Voeis::CVController
  rescue_from ActionView::MissingTemplate, :with => :invalid_page

  ###GLOBAL ValueTypeCV controller
  before_filter do
    @cv_global = true
    @cv_class = Voeis::ValueTypeCV
    @cv_type = :value_type
    init(@cv_type,@cv_class,@cv_global)
  end
  
end