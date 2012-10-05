class Voeis::SensorTypeCVsController < Voeis::CVController
  rescue_from ActionView::MissingTemplate, :with => :invalid_page

  ###LOCAL SensorTypeCV controller
  before_filter do
    @cv_global = false
    @cv_class = Voeis::SensorTypeCV
    @cv_type = :sensor_type
    init(@cv_type,@cv_class,@cv_global)
  end
  
end