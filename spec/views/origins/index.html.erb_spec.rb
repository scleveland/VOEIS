require 'spec_helper'

describe "origins/index.html.erb" do
  before(:each) do
    assign(:origins, [
      stub_model(Origin),
      stub_model(Origin)
    ])
  end

  it "renders a list of origins" do
    render
  end
end
