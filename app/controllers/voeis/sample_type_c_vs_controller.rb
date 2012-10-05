class Voeis::SampleTypeCVsController < Voeis::CVController
  rescue_from ActionView::MissingTemplate, :with => :invalid_page

  ###LOCAL SampleTypeCV controller
  before_filter do
    @cv_global = false
    @cv_class = Voeis::SampleTypeCV
    @cv_type = :sample_type
    init(@cv_type,@cv_class,@cv_global)
  end
  
end