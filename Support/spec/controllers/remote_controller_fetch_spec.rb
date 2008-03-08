require File.dirname(__FILE__) + '/../spec_helper'

describe RemoteController do
  include SpecHelpers
  
  before(:each) do
    Git.reset_mock!
  end
  
  describe "fetching" do
    before(:each) do
      # query the sources
      Git.command_response["branch"] = "* master\n"
      Git.command_response["config", "branch.master.remote"] = %Q{origin}
      Git.command_response["remote"] = %Q{origin}
    
      # query the config - if source != self["remote.#{current_branch}.remote"] || self["remote.#{current_branch}.merge"].nil?
    
      # Git.command_response[] 
      Git.command_response["fetch", "origin"] = fixture_file("fetch_1_5_4_3_output.txt")
      
      @output = capture_output do
        dispatch :controller => "remote", :action => "fetch"
      end
    end
    
    it "should output log of changes pulled" do
      # puts htmlize(@output)
      puts Git.commands_ran.inspect
    end
  end
end