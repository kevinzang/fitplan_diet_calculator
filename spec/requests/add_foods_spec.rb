require 'spec_helper'

describe "AddFoods" do
  describe "GET /add_foods" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get add_foods_path
      response.status.should be(200)
    end
  end
end
