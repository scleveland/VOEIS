class SearchController < ApplicationController
# The search controller!

  def project
    @project = Project.get(params[:id])
  end

end