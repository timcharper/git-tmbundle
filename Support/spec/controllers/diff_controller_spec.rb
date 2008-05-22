require File.dirname(__FILE__) + '/../spec_helper'

describe DiffController do
  include SpecHelpers
  include Parsers
  before(:each) do
    Git.reset_mock!
    @git = Git.singleton_new
  end
  
  describe "uncommitted changes" do
    before(:each) do
      @git.should_receive(:diff).
        with(:path => @git.path, :since => "HEAD" ).
        and_return(
          parse_diff(fixture_file("changed_files.diff"))
        )
      
      @git.submodule.stub!(:all).and_return []
      
      @output = capture_output do 
        dispatch(:controller => "diff", :action => "uncommitted_changes")
      end
    end
    
    it "should output the diff" do
      # puts Git.commands_ran.inspect
      # puts @output
      @output.should include("Support/lib/formatters/diff.rb")
    end
    
    it "should show a link to open the diff in textmate" do
      @output.should include("Open diff in TextMate")      
    end
    
    it "should include a javascript include tag for prototype.js" do
      @output.should include("prototype.js")
    end
  end
  
  describe "diffing submodules" do
    before(:each) do
      @git.should_receive(:diff).
        and_return(
          parse_diff(fixture_file("submodules.diff"))
        )
      @output = capture_output do 
        dispatch(:controller => "diff", :action => "diff")
      end
    end
    
    it "should report the added submodule" do
      @output.should include("Submodule added")
    end
    
    it "should report the deleted submodule" do
      @output.should include("Submodule deleted")
    end
    
    it "should report the modified submodule" do
      @output.should include("Submodule modified")
    end
  end
end