class DataTypeCVsController < Voeis::CVController
  rescue_from ActionView::MissingTemplate, :with => :invalid_page

  ###GLOBAL DataTypeCV controller
  before_filter do
    @cv_global = true
    @cv_class = Voeis::DataTypeCV
    @cv_type = :data_type
    init(@cv_type,@cv_class,@cv_global)
  end
  
end