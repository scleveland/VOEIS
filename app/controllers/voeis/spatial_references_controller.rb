class Voeis::SpatialReferencesController < Voeis::CVController
  rescue_from ActionView::MissingTemplate, :with => :invalid_page

  ###LOCAL SpatialReference controller
  before_filter do
    @cv_global = false
    @cv_class = Voeis::SpatialReference
    @cv_type = :spatial_reference
    init(@cv_type,@cv_class,@cv_global)
  end

end