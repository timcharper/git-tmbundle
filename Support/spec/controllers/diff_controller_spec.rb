require File.dirname(__FILE__) + '/../spec_helper'

describe DiffController do
  include SpecHelpers
    
  before(:each) do
    Git.reset_mock!
  end
  
  describe "uncommitted changes" do
    before(:each) do
      Git.command_response["diff", "."] = fixture_file("changed_files.diff")
      @output = capture_output do 
        dispatch(:controller => "diff", :action => "uncommitted_changes")
      end
    end
    
    it "should output the diff" do
      # puts Git.commands_ran.inspect
      @output.should include("Support/lib/formatters/diff.rb")
    end
    
    it "should show a link to open the diff in textmate" do
      @output.should include("Open diff in TextMate")      
    end
    
    it "should include a javascript include tag for prototype.js" do
      @output.should include("prototype.js")
    end
  end
end