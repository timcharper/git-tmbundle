require File.dirname(__FILE__) + '/../spec_helper'

describe SCM::Git do
  before(:each) do
    @git = SCM::Git.new
    Git.reset_mock!
  end
  
  describe "when getting branches" do
    before(:each) do
    end
    
    it "should get the right prefix for an origin" do
      Git.command_output << "+refs/heads/*:refs/remotes/satellite/*"
      @git.branch.remote_branch_prefix("satellite").should == "satellite"
    end
    
    it "should retrieve all remote branches for a given origin" do
      Git.command_output << <<-EOF
  asdf
* master
  mybranch
  satellite
  origin/master
  origin/mybranch
  satellite/asdf
  satellite/master
  satellite/mybranch
  satellite/satellite
      EOF
      Git.command_output << "+refs/heads/*:refs/remotes/satellite/*"
      
      branches = @git.branch.list(:remote, :remote => "satellite")
      branches.map{|r|r[:name]}.should == ["satellite/asdf", "satellite/master", "satellite/mybranch", "satellite/satellite"]
    end
  end
  
  it "should describe a revision, defaulting to use all refs" do
    Git.command_response["describe", "--all", "1234"] = "tag-1234\n"
    `ls` # set the exit status code to 0
    @git.describe("1234").should == "tag-1234"
  end
  
  it "should return the current revision" do
    Git.command_response["rev-parse", "HEAD"] = "1234\n"
    @git.current_revision.should == "1234"
  end

end
