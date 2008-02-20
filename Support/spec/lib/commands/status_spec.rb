require File.dirname(__FILE__) + '/../../spec_helper'

describe SCM::Git::Status do
  before(:each) do
    @status = SCM::Git::Status.new
    Git.command_response["status"] = fixture_file("status_output.txt")
  end
  
  include SpecHelpers
  
  describe "when executing from a base directory" do
    before(:each) do
      @results = @status.status
    end
    
    it "should execute a parse and return a sorted list of SCM commit dialog statuses" do
      @results.map{ |result| result[:path] }.should == [
        "/base/dir/", 
        "/base/directory.txt", 
        "/base/new_file_and_added.txt", 
        "/base/project.txt", 
        "/base/small.diff"
      ]
    end
    
    it "should parse appropriate statuses" do
      @results.map{ |result| result[:status][:short] }.should == ["?", "?", "A", "M", "D"]
    end
  end
  
  it "should filter to a folder" do
    File.should_receive(:directory?).with("/base/dir").and_return(true)
    @results = @status.status("/base/dir")
    @results.map{ |result| result[:path] }.should == [
      "/base/dir/"
    ]
  end
  
  it "should filter to a file" do
    File.should_receive(:directory?).with("/base/small.diff").and_return(false)
    @results = @status.status("/base/small.diff")
    @results.map{ |result| result[:path] }.should == [
      "/base/small.diff"
    ]
  end
  
  it "should filter to a subfolder" do
    File.should_receive(:directory?).with("/base/dir/subfolder").and_return(true)
    @results = @status.status("/base/dir/subfolder")
    @results.should have(1).result
    @result = @results.first
    @result[:path].should == "/base/dir/subfolder/"
    @result[:display].should == "dir/subfolder/"
  end
  
  it "should parse a status document correctly" do
    result = @status.parse_status(fixture_file("status_output.txt"))
    result.should == {"dir/"=>"?",
     "new_file_and_added.txt"=>"A",
     "small.diff"=>"D",
     "directory.txt"=>"?",
     "project.txt"=>"M"
    }
  end
end