require 'spec_helper'

describe OriginsController do

  def mock_origin(stubs={})
    (@mock_origin ||= mock_model(Origin).as_null_object).tap do |origin|
      origin.stub(stubs) unless stubs.empty?
    end
  end

  describe "GET index" do
    it "assigns all origins as @origins" do
      Origin.stub(:all) { [mock_origin] }
      get :index
      assigns(:origins).should eq([mock_origin])
    end
  end

  describe "GET show" do
    it "assigns the requested origin as @origin" do
      Origin.stub(:get).with("37") { mock_origin }
      get :show, :id => "37"
      assigns(:origin).should be(mock_origin)
    end
  end

  describe "GET new" do
    it "assigns a new origin as @origin" do
      Origin.stub(:new) { mock_origin }
      get :new
      assigns(:origin).should be(mock_origin)
    end
  end

  describe "GET edit" do
    it "assigns the requested origin as @origin" do
      Origin.stub(:get).with("37") { mock_origin }
      get :edit, :id => "37"
      assigns(:origin).should be(mock_origin)
    end
  end

  describe "POST create" do

    describe "with valid params" do
      it "assigns a newly created origin as @origin" do
        Origin.stub(:new).with({'these' => 'params'}) { mock_origin(:save => true) }
        post :create, :origin => {'these' => 'params'}
        assigns(:origin).should be(mock_origin)
      end

      it "redirects to the created origin" do
        Origin.stub(:new) { mock_origin(:save => true) }
        post :create, :origin => {}
        response.should redirect_to(origin_url(mock_origin))
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved origin as @origin" do
        Origin.stub(:new).with({'these' => 'params'}) { mock_origin(:save => false) }
        post :create, :origin => {'these' => 'params'}
        assigns(:origin).should be(mock_origin)
      end

      it "re-renders the 'new' template" do
        Origin.stub(:new) { mock_origin(:save => false) }
        post :create, :origin => {}
        response.should render_template("new")
      end
    end

  end

  describe "PUT update" do

    describe "with valid params" do
      it "updates the requested origin" do
        Origin.should_receive(:get).with("37") { mock_origin }
        mock_origin.should_receive(:update).with({'these' => 'params'})
        put :update, :id => "37", :origin => {'these' => 'params'}
      end

      it "assigns the requested origin as @origin" do
        Origin.stub(:get) { mock_origin(:update => true) }
        put :update, :id => "1"
        assigns(:origin).should be(mock_origin)
      end

      it "redirects to the origin" do
        Origin.stub(:get) { mock_origin(:update => true) }
        put :update, :id => "1"
        response.should redirect_to(origin_url(mock_origin))
      end
    end

    describe "with invalid params" do
      it "assigns the origin as @origin" do
        Origin.stub(:get) { mock_origin(:update => false) }
        put :update, :id => "1"
        assigns(:origin).should be(mock_origin)
      end

      it "re-renders the 'edit' template" do
        Origin.stub(:get) { mock_origin(:update => false) }
        put :update, :id => "1"
        response.should render_template("edit")
      end
    end

  end

  describe "DELETE destroy" do
    it "destroys the requested origin" do
      Origin.should_receive(:get).with("37") { mock_origin }
      mock_origin.should_receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "redirects to the origins list" do
      Origin.stub(:get) { mock_origin }
      delete :destroy, :id => "1"
      response.should redirect_to(origins_url)
    end
  end

end
