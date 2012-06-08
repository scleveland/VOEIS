require "spec_helper"

describe OriginsController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/origins" }.should route_to(:controller => "origins", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/origins/new" }.should route_to(:controller => "origins", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/origins/1" }.should route_to(:controller => "origins", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/origins/1/edit" }.should route_to(:controller => "origins", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/origins" }.should route_to(:controller => "origins", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/origins/1" }.should route_to(:controller => "origins", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/origins/1" }.should route_to(:controller => "origins", :action => "destroy", :id => "1")
    end

  end
end
