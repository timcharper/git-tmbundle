require File.dirname(__FILE__) + '/../spec_helper'

describe ConfigController do
  include SpecHelpers
  include Parsers
  
  before(:each) do
    @controller = ConfigController.singleton_new
    @git = Git.singleton_new
  end
  
  describe "when setting values" do
    it "should default to local" do
      @git.config.should_receive(:[]=).with("local", "user.name", "My Name")
      capture_output { dispatch(:controller => "config", :action => "set", :key => "user.name", :value => "My Name" )}
    end
  
    it "should allow setting of global variables" do
      @git.config.should_receive(:[]=).with("global", "user.name", "My Name")
      capture_output { dispatch(:controller => "config", :action => "set", :scope => "global", :key => "user.name", :value => "My Name" )}
    end
  end
  
end