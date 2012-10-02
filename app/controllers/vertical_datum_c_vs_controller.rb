class VerticalDatumCVsController < Voeis::CVController
  rescue_from ActionView::MissingTemplate, :with => :invalid_page

  ###GLOBAL VerticalDatumCV controller
  before_filter do
    @cv_global = true
    @cv_class = Voeis::VerticalDatumCV
    @cv_type = :vertical_datum
    init(@cv_type,@cv_class,@cv_global)
  end
  
end