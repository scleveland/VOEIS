require 'spec_helper'

describe "origins/edit.html.erb" do
  before(:each) do
    @origin = assign(:origin, stub_model(Origin))
  end

  it "renders the edit origin form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => origin_path(@origin), :method => "post" do
    end
  end
end
