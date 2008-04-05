require File.dirname(__FILE__) + '/../spec_helper'

describe TagController do
  include SpecHelpers
  include Parsers
  
  before(:each) do
    @controller = TagController.singleton_new
    @git = Git.singleton_new
  end
  
  it "should allow you to abort" do
    @controller.should_receive(:prompt_tag_name).and_return(false)
    capture_output { dispatch :controller => "tag", :action => "create" }.should include("Aborted")
  end
  
  it "should not push the tag if prompt_want_to_push_remote returns false" do
    @controller.should_receive(:prompt_tag_name).and_return("mytab")
    @git.should_receive(:create_tag).and_return(true)
    @controller.should_receive(:prompt_want_to_push_remote).and_return(false)
    @controller.should_not_receive(:render_component)
    
    capture_output { dispatch :controller => "tag", :action => "create" }
  end
end