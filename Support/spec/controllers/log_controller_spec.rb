require File.dirname(__FILE__) + '/../spec_helper'
require CONTROLLERS_ROOT + "/log_controller.rb"
describe LogController do
  include SpecHelpers
  
  before(:each) do
    Git.reset_mock!
    @git = Git.singleton_new
  end
  
  describe "showing a log" do
    before(:each) do
      Git.command_response["log", "-n", Git::Config::DEFAULT_LOG_LIMIT, "."] = fixture_file("log.txt")
      @git.branch.stub!(:current).and_return branch_stub(:name => "refs/heads/master")
      @output = capture_output do
        dispatch :controller => "log", :action => "index", :path => "."
      end
    end
    
    it "should include render with a layout" do
      @output.should include("<html>")
    end
    
    it "should show a log" do
      @output.should include("<strong>198fc930</strong>")
    end
  end
  
  describe "showing outgoing changes" do
    before(:each) do
      @controller = LogController.singleton_new
      @git = Git.singleton_new
      
      @master  = branch_stub(:name => "refs/heads/master",  :tracking_status => :behind,    :tracking_branch_name => "refs/remotes/origin/master")
      @release = branch_stub(:name => "refs/heads/release", :tracking_status => :ahead,     :tracking_branch_name => "refs/remotes/origin/release")
      @task    = branch_stub(:name => "refs/heads/task",    :tracking_status => :diverged,  :tracking_branch_name => "refs/remotes/origin/task")
    end
    
    it "should show an outgoing log for all diverged or ahead branches" do
      @git.branch.stub!(:all).and_return([@master, @release, @task])
      @git.submodule.stub!(:all).and_return([])
      
      @controller.should_receive(:render_component).with(:action => "log", :git_path => @git.path, :branches => "refs/remotes/origin/release..refs/heads/release")
      @controller.should_receive(:render_component).with(:action => "log", :git_path => @git.path, :branches => "refs/remotes/origin/task..refs/heads/task")
      
      capture_output do
        dispatch :controller => "log", :action => "outgoing"
      end
    end
    
    it "should show an outgoing branch log for all submodules" do
      @git.branch.stub!(:all).and_return([])
      @submodule = stub("submodule",
        :git => stub("git", 
          :path => "submodule_path", 
          :branch => stub("branch_command",
            :all => [@master, @release, @task]
          )
        )
      )
      
      @git.submodule.stub!(:all).and_return([@submodule])
      
      @controller.should_receive(:render_component).with(:action => "log", :git_path => @submodule.git.path, :branches => "refs/remotes/origin/release..refs/heads/release")
      @controller.should_receive(:render_component).with(:action => "log", :git_path => @submodule.git.path, :branches => "refs/remotes/origin/task..refs/heads/task")
      
      capture_output do
        dispatch :controller => "log", :action => "outgoing"
      end
    end
  end
end