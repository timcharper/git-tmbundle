require File.dirname(__FILE__) + '/../../spec_helper'

describe SCM::Git do
  before(:each) do
    @git = Git.new
    Git.command_response["status"] = fixture_file("status_output.txt")
  end
  
  include SpecHelpers
  
  it "should return the state of an initial_commit_pending? as false" do
    @git.initial_commit_pending?.should == false
  end
  
  it "should return the state of initial_commit_pending? as true when 'git status' reports it as such" do
    Git.command_response["status"] = <<EOF
# On branch master
#
# Initial commit
#
nothing to commit (create/copy files and use "git add" to track)
EOF
    @git.initial_commit_pending?.should == true
  end
  
  describe "when executing from a base directory" do
    before(:each) do
      @results = @git.status
    end
    
    it "should execute a parse and return a sorted list of SCM commit dialog statuses" do
      @results.map{ |result| result[:path] }.should == [
        "/base/app/views/layouts/application.html.erb", 
        "/base/dir/", 
        "/base/directory.txt", 
        "/base/new_file_and_added.txt", 
        "/base/project.txt", 
        "/base/small.diff"
      ]
    end
    
    it "should parse appropriate statuses" do
      @results.map{ |result| result[:status][:short] }.should == ["R", "?", "?", "A", "M", "D"]
    end
  end
  
  it "should filter to a folder" do
    File.should_receive(:directory?).with("/base/dir").and_return(true)
    @results = @git.status("/base/dir")
    @results.map{ |result| result[:path] }.should == [
      "/base/dir/"
    ]
  end
  
  it "should filter to a file" do
    File.should_receive(:directory?).with("/base/small.diff").and_return(false)
    @results = @git.status("/base/small.diff")
    @results.map{ |result| result[:path] }.should == [
      "/base/small.diff"
    ]
  end
  
  it "should filter to a subfolder" do
    File.should_receive(:directory?).with("/base/dir/subfolder").and_return(true)
    @results = @git.status("/base/dir/subfolder")
    @results.should have(1).result
    @result = @results.first
    @result[:path].should == "/base/dir/subfolder/"
    @result[:display].should == "dir/subfolder/"
  end
  
  it "should auto-expand the path when filtering to a relative path" do
    File.should_receive(:directory?).with("/base/dir/subfolder").and_return(true)
    @results = @git.status("dir/subfolder")
    @results.should have(1).result
    @result = @results.first
    @result[:path].should == "/base/dir/subfolder/"
    @result[:display].should == "dir/subfolder/"
  end
  
  it "should parse a status document correctly" do
    result = @git.parse_status_hash(fixture_file("status_output.txt"))
    result.should == {"dir/"=>"?",
     "new_file_and_added.txt"=>"A",
     "small.diff"=>"D",
     "directory.txt"=>"?",
     "project.txt"=>"M",
     "app/views/layouts/application.html.erb" => "R"
     
    }
  end
  
  it "should recognize conflict markers" do
    @git.file_has_conflict_markers("#{FIXTURES_DIR}/conflict.txt").should == true
    @git.file_has_conflict_markers("#{FIXTURES_DIR}/log.txt").should == false
  end
end