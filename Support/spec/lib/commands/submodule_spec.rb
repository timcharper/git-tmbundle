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
+23f26dec3851f50dbd4f7a132735b962b436898e great-module
 e741e43171fd34c98ef98afa5877fb2d74841b82 mod (undefined)
EOF
    submodules = @git.submodule.all
    submodules.should have(3).submodules
    
    submodules[0].revision.should == "03a20cfe2e0e344f87ac3132ddc991899cef2567"
    submodules[0].name.should == "fixture-scenarios"
    submodules[0].state.should == -1
    submodules[0].tag.should be_nil

    submodules[1].revision.should == "23f26dec3851f50dbd4f7a132735b962b436898e"
    submodules[1].name.should == "great-module"
    submodules[1].state.should == +1
    submodules[1].tag.should be_nil
    
    submodules[2].revision.should == "e741e43171fd34c98ef98afa5877fb2d74841b82"
    submodules[2].name.should == "mod"
    submodules[2].state.should == 0
    submodules[2].tag.should be_nil
  end
  
  it "should add a repository" do
    repo = "git@server:/repository.git"
    path = "my-path"
    Git.command_response["submodule", "add", "--", repo, path] = ""
    @git.submodule.add(repo, "/base/#{path}")
    Git.commands_ran.should == [["submodule", "add", "--", repo, path]]
  end
  
  it "should ignore 'fatal cannot describe' errors" do
    Git.command_response["submodule"] = <<EOF
fatal: cannot describe '23f26dec3851f50dbd4f7a132735b962b436898e'
 23f26dec3851f50dbd4f7a132735b962b436898e mod (undefined)
EOF
    submodules = @git.submodule.all
    submodules.should have(1).submodules
  end
end
