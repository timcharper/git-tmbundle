require File.dirname(__FILE__) + '/../spec_helper'

describe MiscController do
  include SpecHelpers
  
  before(:each) do
    Git.reset_mock!
  end
  
  it "should initialize a repository" do
    output = capture_output do
      dispatch(:controller => "misc", :action => "init");
    end
    Git.commands_ran.should == [ ["init"]]
  end
end