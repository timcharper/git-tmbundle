require File.dirname(__FILE__) + '/../../spec_helper'

describe SCM::Git::Branch do
  before(:each) do
    @git = Git.new
    Git.reset_mock!
    @HEAD_file_path = @git.path_for(".git/HEAD")
  end
  
  include SpecHelpers
  
  it "should detect when not on a branch" do
    File.stub!(:read).with(@HEAD_file_path).and_return("12345678")
    @git.branch.current_name.should == nil
  end
  
  it "should return the short version of the current branch by default" do
    File.stub!(:read).with(@HEAD_file_path).and_return("ref: refs/heads/master")
    @git.branch.current_name.should == "master"
  end
  
  it "should return the long version of the current branch" do
    File.stub!(:read).with(@HEAD_file_path).and_return("ref: refs/heads/master")
    @git.branch.current_name(:long).should == "refs/heads/master"
  end
  
  describe "listing branches" do
    before(:each) do
      Git.command_response["for-each-ref", "refs/heads"] = <<EOF
7dd2ef4bbb97536b1c4a014d87eafbb4b41030e8 commit	refs/heads/test_mod
59514d9864d25aa8250aea90f316638529b97801 commit	refs/heads/master
EOF
      Git.command_response["for-each-ref", "refs/remotes"] = <<EOF
7dd2ef4bbb97536b1c4a014d87eafbb4b41030e8 commit	refs/remotes/origin/alpha
59514d9864d25aa8250aea90f316638529b97801 commit	refs/remotes/origin/test_mod
59514d9864d25aa8250aea90f316638529b97801 commit	refs/remotes/origin/master
EOF
    end
    
    it "should return a list of branches" do
      @git.branch.all.should have(5).branches
    end
    
    it "should filter to the remote branches" do
      @git.branch.all(:remote).should have(3).branches
    end
    
    it "should filter to the local branches" do
      @git.branch.all(:local).should have(2).branches
    end
    
    it "should by default shorten the branch names" do
      @git.branch.all(:local).first.name.should == "test_mod"
      @git.branch.all(:remote).first.name.should == "origin/alpha"
    end
    
    it "should filter to a remote" do
      @git.remote["origin"].should_receive(:remote_branch_prefix).and_return("refs/remotes/origin/")
      @git.remote["gitorious"].should_receive(:remote_branch_prefix).and_return("refs/remotes/gitorious/")
      @git.branch.all(:remote, :remote => "origin").should have(3).branches
      @git.branch.all(:remote, :remote => "gitorious").should have(0).branches
    end
    
    it "discern remote and local" do
      @git.branch.all(:local).first.should be_local
      @git.branch.all(:remote).first.should be_remote
    end
    
    it "should know if it's the current branch or not" do
      branch = @git.branch.all(:local).first
      File.stub!(:read).with(@HEAD_file_path).and_return("ref: #{branch.name(:full)}")
      branch.should be_current
      
      File.stub!(:read).with(@HEAD_file_path).and_return("1234")
      branch.should_not be_current
    end
    
    it "should return the the current branch" do
      File.stub!(:read).with(@HEAD_file_path).and_return("ref: refs/heads/master")
      @git.branch.current.name.should == "master"
    end
  end
end
