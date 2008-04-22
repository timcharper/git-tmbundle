require File.dirname(__FILE__) + '/../spec_helper'

describe MiscController do
  include SpecHelpers
  
  before(:each) do
    @git = Git.singleton_new
  end
  
  it "should initialize a repository" do
    @git.should_receive(:init)
    output = capture_output do
      dispatch(:controller => "misc", :action => "init");
    end
  end
end