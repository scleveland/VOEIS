class SpeciationCVsController < Voeis::CVController
  rescue_from ActionView::MissingTemplate, :with => :invalid_page

  ###GLOBAL SpeciationCV controller
  before_filter do
    @cv_global = true
    @cv_class = Voeis::SpeciationCV
    @cv_type = :speciation
    init(@cv_type,@cv_class,@cv_global)
  end
  
end