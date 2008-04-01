require File.dirname(__FILE__) + '/../../spec_helper'

describe SCM::Git::Submodule do
  before(:each) do
    @git = Git.new
    Git.reset_mock!
    
    Git.command_response["submodule"] = <<EOF
 e741e43171fd34c98ef98afa5877fb2d74841b82 mod (undefined)
EOF
  end
  include SpecHelpers
  
  it "should return all submodules" do
    submodules = @git.submodule.all
    submodules.should have(1).submodule
    submodule = submodules.first
    
    submodule.revision.should == "e741e43171fd34c98ef98afa5877fb2d74841b82"
    submodule.name.should == "mod"
    submodule.tag.should be_nil
  end
end
