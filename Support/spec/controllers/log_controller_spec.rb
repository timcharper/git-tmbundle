require File.dirname(__FILE__) + '/../spec_helper'
require CONTROLLERS_ROOT + "/log_controller.rb"
describe LogController do
  include SpecHelpers
  
  before(:each) do
    Git.reset_mock!
  end
  
  describe "showing a log" do
    before(:each) do
      Git.command_response["log", ".", "-n", LogController::DEFAULT_LOG_LIMIT] = fixture_file("log.txt")
      Git.command_response["branch"] = "* master\n  task"
      @output = capture_output do
        dispatch :controller => "log", :action => "index"
      end
    end
    
    after(:each) do
      # puts Git.commands_ran.inspect
    end
    
    it "should show a log" do
      @output.should include("<strong>198fc930</strong>")
    end
  end
end