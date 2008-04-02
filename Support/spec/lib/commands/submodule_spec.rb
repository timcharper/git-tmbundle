require File.dirname(__FILE__) + '/../../spec_helper'

describe SCM::Git::Submodule do
  before(:each) do
    @git = Git.new
    Git.reset_mock!
    
  end
  include SpecHelpers
  
  it "should return all submodules when listing one" do
    Git.command_response["submodule"] = <<EOF
-03a20cfe2e0e344f87ac3132ddc991899cef2567 fixture-scenarios
 e741e43171fd34c98ef98afa5877fb2d74841b82 mod (undefined)
EOF
    submodules = @git.submodule.all
    submodules.should have(2).submodules
    
    submodules[0].revision.should == "03a20cfe2e0e344f87ac3132ddc991899cef2567"
    submodules[0].name.should == "fixture-scenarios"
    submodules[0].tag.should be_nil
    
    submodules[1].revision.should == "e741e43171fd34c98ef98afa5877fb2d74841b82"
    submodules[1].name.should == "mod"
    submodules[1].tag.should be_nil
  end
  
  it "should add a repository" do
    @git.submodule.add("git@server:/repository.git", "/base/my-path")
    Git.commands_ran.should == [["submodule", "add", "--", "git@server:/repository.git", "my-path"]]
  end
end
