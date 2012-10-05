class GeneralCategoryCVsController < Voeis::CVController
  rescue_from ActionView::MissingTemplate, :with => :invalid_page

  ###GLOBAL GeneralCategoryCV controller
  before_filter do
    @cv_global = true
    @cv_class = Voeis::GeneralCategoryCV
    @cv_type = :general_category
    init(@cv_type,@cv_class,@cv_global)
  end
  
end