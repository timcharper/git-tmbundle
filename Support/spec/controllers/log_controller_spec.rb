require File.dirname(__FILE__) + '/../spec_helper'
require CONTROLLERS_ROOT + "/log_controller.rb"
describe LogController do
  include SpecHelpers
  
  before(:each) do
    Git.reset_mock!
  end
  
  describe "showing a log" do
    before(:each) do
      Git.command_response["log", "-n", LogController::DEFAULT_LOG_LIMIT, "."] = fixture_file("log.txt")
      Git.command_response["branch"] = "* master\n  task"
      @output = capture_output do
        dispatch :controller => "log", :action => "index", :path => "."
      end
    end
    
    after(:each) do
      # puts Git.commands_ran.inspect
    end
    
    it "should include render with a layout" do
      @output.should include("<html>")
    end
    it "should show a log" do
      # puts htmlize(@output)
      @output.should include("<strong>198fc930</strong>")
    end
  end
  # 
  # describe "when running" do
  #   before(:each) do
  #     Git.command_output << fixture_file("log_with_diffs.txt")
  #     Git.command_output << "* master\n  task"
  #     
  #     @output = capture_output do
  #       results = @log.run
  #     end
  #     @h = Hpricot(@output)
  #   end
  #   
  #   it_should_behave_like "Formatter with layout"
  #   
  #   it "should output the revision in short format" do
  #     rev_output = (@h / ".infobox > span > strong").first.to_s
  #     # rev_output.should include("Revision")
  #     rev_output.should match(/\b3dce1220\b/)
  #   end
  #   
  #   it "should output div tags with the current branch" do
  #     tag = (@h / "div#detail_master_3dce12204f8b81535ce10f579a78d71aa3fa1730").first
  #     tag.should_not be_nil
  #     
  #     tag.attributes["branch"].should == "master"
  #     tag.attributes["rev"].should == "3dce12204f8b81535ce10f579a78d71aa3fa1730"
  #     
  #   end
  #   # puts htmlize(@output)
  # end
  # 
end