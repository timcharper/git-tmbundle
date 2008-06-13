require File.dirname(__FILE__) + '/../spec_helper'

describe SCM::Git do
  before(:each) do
    @git = SCM::Git.new
    Git.reset_mock!
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
  
  it "should auto_add_rm files depending on their existence" do
    File.stub!(:exist?).with("/base/existing_file.txt").and_return(true)
    File.stub!(:exist?).with("/base/deleted_file.txt").and_return(false)
    @git.should_receive(:add).with(["existing_file.txt"]).and_return("")
    @git.should_receive(:rm).with(["deleted_file.txt"]).and_return("")
    @git.auto_add_rm(["existing_file.txt", "deleted_file.txt"])
  end
  
  describe "using submodule git relative paths" do
    before(:each) do
      @sub_git = Git.new(:parent => @git, :path => File.join(@git.path, "subproject"));
    end
    
    it "should return absolute paths" do
      @sub_git.path_for("file.txt").should == File.join(@git.path, "subproject/file.txt")
    end
    
    it "should return a relative path from the root git" do
      @sub_git.root_relative_path_for("file.txt").should == "subproject/file.txt"
    end
  end
  it

end
