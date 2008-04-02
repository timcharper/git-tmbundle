require File.dirname(__FILE__) + "/spec_helper.rb"
describe HtmlHelpers do
  def resource_url(arg); arg; end
  it "should output a javascript_include_tag" do
    javascript_include_tag("prototype.js").should == ["<script src=\"prototype.js\" type=\"text/javascript\"></script>"]
  end
  
  it "should format options_for_javascript, escaping appropriately" do
    options_for_javascript(:controller => "log", :action => "index", :param => 'Grand "old" time').should == %!{action: "index", controller: "log", param: "Grand \\"old\\" time"}!
  end
end