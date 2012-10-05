class LoggerTypeCVsController < Voeis::CVController
  rescue_from ActionView::MissingTemplate, :with => :invalid_page

  ###GLOBAL LoggerTypeCV controller
  before_filter do
    @cv_global = true
    @cv_class = Voeis::LoggerTypeCV
    @cv_type = :logger_type
    init(@cv_type,@cv_class,@cv_global)
  end
  
end