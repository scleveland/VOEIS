class SampleMediumCVsController < Voeis::CVController
  rescue_from ActionView::MissingTemplate, :with => :invalid_page

  ###GLOBAL SampleMediumCV controller
  before_filter do
    @cv_global = true
    @cv_class = Voeis::SampleMediumCV
    @cv_type = :sample_medium
    init(@cv_type,@cv_class,@cv_global)
  end
  
end