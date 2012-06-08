require 'spec_helper'

describe "origins/show.html.erb" do
  before(:each) do
    @origin = assign(:origin, stub_model(Origin))
  end

  it "renders attributes in <p>" do
    render
  end
end
