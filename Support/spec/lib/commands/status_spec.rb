require File.dirname(__FILE__) + '/../../spec_helper'

describe SCM::Git::Status do
  before(:all) do
    stub_command_runner(SCM::Git::Status)
  end
  
  before(:each) do
    @status = SCM::Git::Status.new
  end
  
  include SpecHelpers
  
  describe "when executing" do
    before(:each) do
      @status.command_output << fixture_file("status_output.txt")

      @results = @status.status
    end
    
    it "should execute a parse and return a sorted list of SCM commit dialog statuses" do
      @results.map{|result| result[:path]}.should == [
        "/base/dir", 
        "/base/new_file.txt", 
        "/base/new_file_and_added.txt", 
        "/base/project.txt", 
        "/base/small.diff"
      ]
    end
    
    it "should parse appropriate statuses" do
      @results.map{|result| result[:status][:short]}.should == ["?", "?", "A", "M", "D"]
    end
  end
  
  it "should parse a status document correctly" do
    result = @status.parse_status(fixture_file("status_output.txt"))
    result.should == {"dir/"=>"?",
     "new_file_and_added.txt"=>"A",
     "small.diff"=>"D",
     "new_file.txt"=>"?",
     "project.txt"=>"M"
    }
  end
end