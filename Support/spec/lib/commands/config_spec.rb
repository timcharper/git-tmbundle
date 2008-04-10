require File.dirname(__FILE__) + '/../../spec_helper'

describe SCM::Git do
  before(:each) do
    @git = SCM::Git.new
    Git.reset_mock!
  end
  
  it "should let git decide when local/global not specified" do
    Git.command_response["config", "remote.origin.url"] = "../origin"
    value = @git.config["remote.origin.url"]
    Git.commands_ran.first.should == ["config", "remote.origin.url"]
    value.should == "../origin"
  end

  it "should default to local when writing" do
    Git.command_response["config", "remote.origin.url", "../origin"] = ""
    @git.config["remote.origin.url"] = "../origin"
    Git.commands_ran.first.should == ["config", "remote.origin.url", "../origin"]
  end

  it "should allow reading of local values" do
    Git.command_response["config", "--file", "/base/.git/config", "remote.origin.url"] = "../origin"
    value = @git.config[:local, "remote.origin.url"]
    Git.commands_ran.first.should == ["config", "--file", "/base/.git/config", "remote.origin.url"]
    value.should == "../origin"
  end

  it "should allow writing of local values" do
    Git.command_response["config", "--file", "/base/.git/config", "remote.origin.url", "../origin"] = ""
    @git.config[:local, "remote.origin.url"] = "../origin"
    Git.commands_ran.first.should == ["config", "--file", "/base/.git/config", "remote.origin.url", "../origin"]
  end
  
  it "should delete local values when assigning nil" do
    @git.config[:local, "git-tmbundle.log.limit"] = nil
    Git.commands_ran.first.should == ["config", "--file", "/base/.git/config", "--unset", "git-tmbundle.log.limit"]
  end
  
  it "should allow reading global values" do
    Git.command_response["config", "--global", "remote.origin.url"] = "../origin"
    value = @git.config[:global, "remote.origin.url"]
    Git.commands_ran.first.should == ["config", "--global", "remote.origin.url"]
    value.should == "../origin"
  end
  
  it "should raise when given a scope it doesn't understand" do
    lambda { @git.config[:boogy, "remote.origin.url"] }.should raise_error("I don't understand the scope :boogy")
  end  
  
  it "should respond to the string version of global as well as the symbol" do
    Git.command_response["config", "--global", "remote.origin.url"] = "../origin"
    @git.config[:global, "remote.origin.url"].should == "../origin"
    @git.config["global", "remote.origin.url"].should == "../origin"
  end
  
  it "should allow writing global values" do
    Git.command_response["config", "--global", "remote.origin.url", "../origin"] = ""
    @git.config[:global, "remote.origin.url"] = "../origin"
    Git.commands_ran.first.should == ["config", "--global", "remote.origin.url", "../origin"]
  end

  it "should return nil on blank, non-existing value" do
    Git.command_output << ""
    @git.config["remote.origin.url"].should be_nil
  end
end